readmeText := "Line1`r`nLine2 with 'single' and "double" quotes."
readmeText := StrReplace(readmeText, "\", "\\")
readmeText := StrReplace(readmeText, "`", "\`")
readmeText := StrReplace(readmeText, "", "")
readmeText := StrReplace(readmeText, "
", "\n")
readmeText := StrReplace(readmeText, "'", "\'")
FileAppend readmeText, test_out.txt
