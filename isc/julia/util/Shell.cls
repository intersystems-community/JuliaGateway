/// Python shell
Class isc.julia.util.Shell
{

/// Start Jupyter Shell.
/// Press enter to quit.
/// do ##class(isc.julia.util.Shell).Shell()
ClassMethod Shell()
{
	try {
		// Multiline mode
		#dim multi As %Boolean = $$$NO
		for {
			write $case(multi, $$$YES:"...", :"J>")
			read command, !
			
			if multi = $$$NO {
				// enter multi mode if line ends on :
				//set multi = ($e($zstrip(command,">W"),*)=":")
			} elseif command = "" {
				// leave multi mode
				set multi = $$$NO
				set command = $g(multiCommand) _ $c(10) _ command
				kill multiCommand
			}
			
			if multi {
				set multiCommand = $g(multiCommand) _ $c(10) _ command
			} else {
				quit:(command="exit()")||(command="")
				set sc = ##class(isc.julia.Main).SimpleString(command, .result)
				if $$$ISOK(sc) {
					write result
				} else {
					write $System.Status.GetOneStatusText(sc)
				}
				write !
			}
		}
	} catch ex {
		#dim ex As %Exception.General
		write ex.DisplayString(),!
	}
}

}

