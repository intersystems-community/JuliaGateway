ARG IMAGE=store/intersystems/iris-community:2019.4.0.383.0
FROM ${IMAGE}

USER root

ENV JULIA_PATH $ISC_PACKAGE_INSTALLDIR/julia
ENV PATH $JULIA_PATH/bin:$PATH

# Because we need TimeZone module
ENV TZ UTC

# https://julialang.org/downloads/
ENV JULIA_VERSION 1.4.0

RUN dpkgArch="$(dpkg --print-architecture)"; \
    folder="$(echo "$JULIA_VERSION" | cut -d. -f1-2)"; \
    wget --no-verbose -O julia.tar.gz "https://julialang-s3.julialang.org/bin/linux/x64/${folder}/julia-${JULIA_VERSION}-linux-x86_64.tar.gz"; \
    mkdir "$JULIA_PATH"; \
    tar -xzf julia.tar.gz --directory="$JULIA_PATH" --strip-components=1; \
    chown -hR $ISC_PACKAGE_IRISUSER:$ISC_PACKAGE_IRISGROUP $JULIA_PATH; \
    rm julia.tar.gz; \
    sed -i $ISC_PACKAGE_INSTALLDIR/iris.cpf -e "s%^LibPath=%LibPath=$JULIA_PATH/lib%"; \
    chown $ISC_PACKAGE_MGRUSER:$ISC_PACKAGE_IRISGROUP $ISC_PACKAGE_INSTALLDIR/iris.cpf; \
    julia --version

# now for InterSystems IRIS

USER $ISC_PACKAGE_MGRUSER

ENV SRC_DIR=/home/$ISC_PACKAGE_MGRUSER

COPY --chown=$ISC_PACKAGE_MGRUSER:$ISC_PACKAGE_IRISGROUP ./isc/ $SRC_DIR/isc
COPY --chown=$ISC_PACKAGE_MGRUSER:$ISC_PACKAGE_IRISGROUP ./rtn/ $SRC_DIR/rtn
COPY --chown=$ISC_PACKAGE_MGRUSER:$ISC_PACKAGE_IRISGROUP iscjulia.so $ISC_PACKAGE_INSTALLDIR/bin/

RUN julia -e 'using Pkg; Pkg.add(["JSON", "CSV", "DataFrames", "MLJ", "MLJModels", "Statistics", "MultivariateStats", "NearestNeighbors"]); using CSV, DataFrames, MLJ, MLJModels, Statistics, MultivariateStats, NearestNeighbors; exit()'

RUN iris start $ISC_PACKAGE_INSTANCENAME && \
    /bin/echo -e "zn \"USER\"" \
            " set sc = ##class(%EnsembleMgr).EnableNamespace(\$Namespace, 1) " \
            " if 'sc  write !,\$System.Status.GetErrorText(sc),!  do \$system.Process.Terminate(, 1)\n" \
            " set sc = \$system.OBJ.ImportDir(\$system.Util.GetEnviron(\"SRC_DIR\") _ \"/isc/julia/\",\"*.cls\", \"c\",,1)\n" \
            " if 'sc  write !,\$System.Status.GetErrorText(sc),!  do \$system.Process.Terminate(, 1)\n" \
            " set ^Ens.Configuration(\"csp\",\"LastProduction\") = \"isc.julia.test.Production\"\n" \
            " set sc = ##class(isc.julia.test.AMES).Import() \n" \
            " zn \"%SYS\"" \
            " set sc = ##class(Security.Users).UnExpireUserPasswords(\"*\")\n" \
            " if 'sc  write !,\$System.Status.GetErrorText(sc),!  do \$system.Process.Terminate(, 1)\n" \
            " set sc = \$system.OBJ.ImportDir(\$system.Util.GetEnviron(\"SRC_DIR\") _ \"/rtn\",\"*.xml\", \"c\")\n" \
            " if 'sc  write !,\$System.Status.GetErrorText(sc),!  do \$system.Process.Terminate(, 1)\n" \
            " do ##class(Security.Users).AddRoles(\"Admin\", \"%ALL\")\n" \
            " do INT^JRNSTOP" \
            " kill ^%SYS(\"JOURNAL\")" \
            " kill ^SYS(\"NODE\")" \
            " halt" \
    | iris session $ISC_PACKAGE_INSTANCENAME && \
 iris stop $ISC_PACKAGE_INSTANCENAME quietly \
  && rm -f $ISC_PACKAGE_INSTALLDIR/mgr/journal.log \
  && rm -f $ISC_PACKAGE_INSTALLDIR/mgr/IRIS.WIJ \
  && rm -f $ISC_PACKAGE_INSTALLDIR/mgr/iris.ids \
  && rm -f $ISC_PACKAGE_INSTALLDIR/mgr/alerts.log \
  && rm -f $ISC_PACKAGE_INSTALLDIR/mgr/journal/* \
  && rm -f $ISC_PACKAGE_INSTALLDIR/mgr/messages.log \
  && rm -rf $SRC_DIR/isc $SRC_DIR/rtn

HEALTHCHECK --interval=5s CMD /irisHealth.sh || exit 1
