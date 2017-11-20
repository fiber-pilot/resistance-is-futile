function display-banner{
    param(
        $message,
        $color,
        $KDBG,
        $prof
    )
    clear-host
    Write-Host "parse-volatility.ps1 by SSgt Richard Hailey III"
    write-host ""
    write-host "Volatility Location = "$volpath
    Write-Host "Memory Location     = "$memfile
    Write-Host "Logfile Location    = "$logpath

    write-host $message -ForegroundColor $color
    
    if($KDBG -eq $null){
        Write-Host "KDBG    =" -ForegroundColor Red
    }
    else{
        Write-Host "KDBG    =" $KDBG -ForegroundColor Green
    }
        if($prof -eq $null){
        Write-Host "Profile =" -ForegroundColor Red
    }
    else{
        Write-Host "Profile =" $prof -ForegroundColor Green
    }
}
function get-imageinfo{
    $imagejob = Start-Job -ScriptBlock $imageblock -ArgumentList $volpath, $memfile -Name imageinfo
    $counter = 0
    while($imagejob.state -eq "Running"){
        $message = "Retrieving Imageinfo, elapsed time = " + $counter
        Clear-Host
        display-banner $message "yellow" $KDBG $prof
        Start-Sleep -Seconds 1
        $counter += 1
    }
    return Receive-Job $imagejob
}
function get-kdbg{
    param(
        $imageinfo
    )
    $imageinfo | ForEach-Object{
        if($_.contains("KDBG")){
        $KDBG = $_.split(":")[1].trim()
        $KDBG = $KDBG.substring(0, ($KDBG.length -1))
        return $KDBG
   }
}
}
function get-profile{
    param(
        $imageinfo
    )
    $imageinfo | ForEach-Object{
        if($_.contains("Suggested Profile")){
            $prof = $_
            if($prof.Contains("Instantiated")){
                $prof = $prof.Split(":")[1].split("(")[0]
                $prof = $prof.split(",")
                $prof = $prof[$prof.Length - 1].trim()
                return $prof
            }
            else{
                $prof = $prof.Split(":")[1]
                $prof = $prof.split(",")
                $prof = $prof[$prof.Length - 1].trim()
                return $prof
            }
        }
    }
}
function make-logpath{
    param($logpath)
    if(!(Test-Path -Path $logpath)){
        New-Item -ItemType Directory -Path $logpath | Out-Null
    }
    else{
        Remove-Item -Path $logpath -Recurse -Force
        New-Item -ItemType Directory -Path $logpath | Out-Null
    }
}
function create-voljobs{
    param(
        $options
    )
    $jobs = @()
    $options | ForEach-Object{
        $jobs += Start-Job -ScriptBlock $jobblock -ArgumentList $volpath, $memfile, $KDBG, $prof, $_ -Name $_
    }
    return $jobs
}
function monitor-jobs{
    param(
        $jobs
    )
    $counter = 0
    while($true){
        $status = $jobs | ForEach-Object {$_.state}
        if(!($status.Contains("Running"))){
            display-banner "All Jobs Complete!" "Magenta" $KDBG $prof
            $jobs | ForEach-Object{
                if($_.state -ne "Completed"){
                    write-host "[-] - " $_.name $_.State -ForegroundColor Yellow
                }
                elseif($_.state -eq "Failed"){
                    write-host "[x] - " $_.name  $_.State -ForegroundColor Yellow
                }
                elseif($_.state -eq "Completed"){
                    write-host "[+] - " $_.name  $_.State -ForegroundColor Green
                }
            }
            break
        }

        display-banner "Parsing Memory" "Yellow" $KDBG $prof
        Write-Host "Elapsed Time "$counter
        $jobs | ForEach-Object{
            if($_.state -ne "Completed"){
                write-host "[-]" $_.name $_.State -ForegroundColor Yellow
            }
            elseif($_.state -eq "Failed"){
                write-host "[x]" $_.name  $_.State -ForegroundColor Yellow
            }
            elseif($_.state -eq "Completed"){
                write-host "[+]" $_.name  $_.State -ForegroundColor Green
            }
        }
        Start-Sleep -Seconds 1
        $counter += 1

    }
}


function main{
    clear-host
    Get-Job | Where-Object{$_.HasMoreData -eq $false} | Remove-Job
    $volpath = "D:\week5\wks02\volatility\volatility.exe"
    $memfile = 'D:\week5\wks02\volatility\SC-WKS02-Snapshot1.vmsn'
    $logpath = "C:\Users\Richard Hailey\Desktop\vol\log"
    $options = "pslist", "netscan", "pstree", "cmdscan", "connections", "test"
    $KDBG = $null
    $prof = $null

    $imageblock = {
        param ($vol, $mem)
        & $vol -f $mem imageinfo 2> $null
    }
    $jobblock = {
        param ($vol, $mem, $kd, $pro, $opt)
        & $vol -f $mem --kdbg=$kd --profile=$pro --output=greptext $opt
    }

    display-banner "Running Imageinfo" "Yellow" $KDBG $prof
    $imageinfo = get-imageinfo
    $KDBG = get-kdbg $imageinfo
    $prof = get-profile $imageinfo
    display-banner "Obtained Imageinfo!" "Green" $KDBG $prof
    make-logpath $logpath
    $jobs = create-voljobs $options
    monitor-jobs $jobs


    $objectTable = @{}
    $jobs = Get-Job
    ForEach($job in $jobs){
        $csv = Receive-Job $job
        if($csv -eq $null){
            continue
        }
        $csv = $csv | ForEach-Object{$_.trim(">|")}
        $obj = ConvertFrom-Csv $csv -Delimiter "|"
        $objectTable.add($job.name, $obj)
    }
}




main