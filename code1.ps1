# Define the path to the desktop
$desktop = [Environment]::GetFolderPath("Desktop")

# Define the file name
$file = Join-Path $desktop "MyFile.txt"

# Create the file and add some text
"Hello, this is a new text file!" | Out-File -FilePath $file -Encoding UTF8
