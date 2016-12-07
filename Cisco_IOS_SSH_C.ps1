Import-Module SSH-Sessions

### Send commands Cisco IOS
Function set-SSH($devices, $ssh){
    function ReadStream($reader)
    {
        $line = $reader.ReadLine();
        while ($line -ne $null)
        {
            $line
            $line = $reader.ReadLine()
        }
    }

    function WriteStream($cmd, $writer, $stream)
    {
        $writer.WriteLine($cmd)
        while ($stream.Length -eq 0)
        {
            start-sleep -milliseconds 1000
        }
    }    

    $stream = $ssh.CreateShellStream("dumb", 80, 24, 800, 600, 1024)

            $reader = new-object System.IO.StreamReader($stream)
            $writer = new-object System.IO.StreamWriter($stream)
            $writer.AutoFlush = $true

            while ($stream.Length -eq 0)
            {
                start-sleep -milliseconds 500
            }
            ReadStream $reader

            foreach ($command in $commands) {

                WriteStream $command $writer $stream
                ReadStream $reader
                Write-Host $reader
                start-sleep -milliseconds 500
            }

            $stream.Dispose()
            $ssh.Disconnect()
            $ssh.Dispose()

}

### Function OpenFile
Function Get-FileName($initialDirectory, $FilterIndex, $Title)
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.FilterIndex = $FilterIndex
    $OpenFileDialog.InitialDirectory = $initialDirectory
    $OpenFileDialog.Filter = "CSV (*.csv)|*.csv|IOS (*.ios)|*.ios"
    $OpenFileDialog.FilterIndex = $FilterIndex
    $OpenFileDialog.Title = $Title
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.Filename
}

### MAIN

### file with Cisco IOS devices
Write-Host "Enter the path of the file with Cisco devices"
$filedevices = Get-FileName ".\" 1 "Cisco Devices"
$devices = Import-Csv -path $filedevices -header 'ip','hostname' -delimiter ';'

### file with commands for Cisco IOS
Write-Host "Enter the path of the file *.ios with commands Cisco IOS"
$fileCommands = Get-FileName ".\" 2 "Cisco Config"
$commands = Get-Content $fileCommands

### Ask Cisco username password
$c=get-credential 
$p=$c.getnetworkcredential().password
$u=$c.Username
$user=$u
$password=$p

$port = 22
for ($i=0; $i -le $devices.Count; $i++){
    $ssh = new-object Renci.SshNet.SshClient($devices[$i].ip, $port, $user, $password)
    Try{
        $ssh.Connect()
        Start-Sleep -s 1
        set-SSH $commands $ssh
       }
       catch{
            }
}
