$volpath = "D:\week5\wks02\volatility\volatility.exe"
$memfile = "D:\week5\wks02\volatility\SC-WKS02-Snapshot1.vmsn"

$imageinfo = & $volpath -f $memfile imageinfo 2> $null


$imageinfo | ForEach-Object{
   if($_.contains("KDBG")){
       $KDBG = $_.split(":")[1].trim()
       $KDBG = $KDBG.substring(0, ($KDBG.length -1))
   }
}
$imageinfo | ForEach-Object{
    if($_.contains("Suggested Profile")){
        $prof = $_
        if($prof.Contains("Instantiated")){
            $prof = $prof.Split(":")[1].split("(")[0]
            $prof = $prof.split(",")
            $prof = $prof[$prof.Length - 1].trim()
        }
        else{
            $prof = $prof.Split(":")[1]
            $prof = $prof.split(",")
            $prof = $prof[$prof.Length - 1].trim()
        }
    }
}

$csv = &$volpath -f $memfile --profile=$prof --kdbg=$KDBG psscan --output=greptext
$csv = $csv | ForEach-Object{$_.trim(">|")}
$obj = ConvertFrom-Csv $csv -Delimiter "|"




function check-ppid{
    Param($process)
    
    $val = $obj | Where-Object {$_.pid -eq $process.ppid}
    if($val -ne $null){
        return $val
    }
    else{
        return $false
    }
}

function recursive-pid{
    Param($process)
    
    $result = @()
    while($true){
        if($result[0] -eq $null){
            $val = check-ppid $process
        }
        else{
            $val = check-ppid $result[$result.length - 1]
        }
        if($val -eq $false){ break }
        else{
            $result += $val
        }
    }
    return $result
}

$newobj = @()

$obj | % {

    $name         = $_.name
    $id           = $_.pid
    $parent_tree  = (recursive-pid $_).name
    $ppid_tree    = (recursive-pid $_).pid

    $newobj += New-Object psobject -Property @{
        Name       = $name
        ParentTree = $parent_tree
        PID        = $id
        PPIDTree   = $ppid_tree
    }
}

$newobj | Format-Table PID, Name, ParentTree, PPIDTree

$malproc = @()
$cleanproc = @()
$rule    = @()
$remaining = @()


$rule += New-Object PSObject -Property @{name = "smss.exe";     parenttree = "System"}
$rule += New-Object PSObject -Property @{name = "svchost.exe";  parenttree = "services.exe", "wininit.exe"}
$rule += New-Object PSObject -Property @{name = "lsass.exe";    parenttree = "wininit.exe"}
$rule += New-Object PSObject -Property @{name = "wininit.exe";  parenttree = "NULL"}
$rule += New-Object PSObject -Property @{name = "taskhost.exe"; parenttree = "services.exe", "wininit.exe"}
$rule += New-Object PSObject -Property @{name = "winlogon.exe"; parenttree = "NULL"}
$rule += New-Object PSObject -Property @{name = "csrss.exe";    parenttree = "NULL"}
$rule += New-Object PSObject -Property @{name = "services.exe"; parenttree = "wininit.exe"}
$rule += New-Object PSObject -Property @{name = "lsm.exe";      parenttree = "wininit.exe"}
$rule += New-Object PSObject -Property @{name = "explorer.exe"; parenttree = "NULL"}
$rule += New-Object PSObject -Property @{name = "iexplore.exe"; parenttree = "explorer.exe"}


$rule += New-Object PSObject -Property @{name = "cmd.exe";      parenttree = "NULL"}
$rule += New-Object PSObject -Property @{name = "SearchProtocol$";      parenttree = "NULL"}






$rule | ForEach-Object{
    $rule_serv = $_.name
    $rule_tree = $_.parenttree

    $service = $newobj | Where-Object {$_.name -eq $rule_serv}
    $service | ForEach-Object{
        if($_.ParentTree -eq $null){
            $test = Compare-Object -ReferenceObject $rule_tree -DifferenceObject "NULL"
        }
        else{
            $test = Compare-Object -ReferenceObject $rule_tree -DifferenceObject $_.parenttree
        }
        if($test -ne $null){
            $malproc += $_
        }
        else{
            $cleanproc += $_
        }
    }
}