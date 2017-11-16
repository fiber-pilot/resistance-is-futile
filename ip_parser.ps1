$global:imageinfo
$global:outpath
$global:memPath
$global:pcapPath
$global:netflowPath
$global:ip_frombox
$global:offset
$global:start
$global:end



<#
$file_source = 'D:\Week 5\Workstation 1\Netflow\New folder\FIWE-2015-netflow.csv'
$memfile =  'D:\Week 5\Workstation 1\Volatility\SC-WKS01-Snapshot1.vmsn'
$pcap_path = 'D:\Week 5\Workstation 1\FIWE-2015_30-31.pcap'#>
#[int]$utc_offset = read-host "what is the utc offset: "

function Import-Xls 
{ 
 
<# 
.SYNOPSIS 
Import an Excel file. 
 
.DESCRIPTION 
Import an excel file. Since Excel files can have multiple worksheets, you can specify the worksheet you want to import. You can specify it by number (1, 2, 3) or by name (Sheet1, Sheet2, Sheet3). Imports Worksheet 1 by default. 
 
.PARAMETER Path 
Specifies the path to the Excel file to import. You can also pipe a path to Import-Xls. 
 
.PARAMETER Worksheet 
Specifies the worksheet to import in the Excel file. You can specify it by name or by number. The default is 1. 
Note: Charts don't count as worksheets, so they don't affect the Worksheet numbers. 
 
.INPUTS 
System.String 
 
.OUTPUTS 
Object 
 
.EXAMPLE 
".\employees.xlsx" | Import-Xls -Worksheet 1 
Import Worksheet 1 from employees.xlsx 
 
.EXAMPLE 
".\employees.xlsx" | Import-Xls -Worksheet "Sheet2" 
Import Worksheet "Sheet2" from employees.xlsx 
 
.EXAMPLE 
".\deptA.xslx", ".\deptB.xlsx" | Import-Xls -Worksheet 3 
Import Worksheet 3 from deptA.xlsx and deptB.xlsx. 
Make sure that the worksheets have the same headers, or have some headers in common, or that it works the way you expect. 
 
.EXAMPLE 
Get-ChildItem *.xlsx | Import-Xls -Worksheet "Employees" 
Import Worksheet "Employees" from all .xlsx files in the current directory. 
Make sure that the worksheets have the same headers, or have some headers in common, or that it works the way you expect. 
 
.LINK 
Import-Xls 
http://gallery.technet.microsoft.com/scriptcenter/17bcabe7-322a-43d3-9a27-f3f96618c74b 
Export-Xls 
http://gallery.technet.microsoft.com/scriptcenter/d41565f1-37ef-43cb-9462-a08cd5a610e2 
Import-Csv 
Export-Csv 
 
.NOTES 
Author: Francis de la Cerna 
Created: 2011-03-27 
Modified: 2011-04-09 
#Requires –Version 2.0 
#> 
 
    [CmdletBinding(SupportsShouldProcess=$true)] 
     
    Param( 
        [parameter( 
            mandatory=$true,  
            position=1,  
            ValueFromPipeline=$true,  
            ValueFromPipelineByPropertyName=$true)] 
        [String[]] 
        $Path, 
     
        [parameter(mandatory=$false)] 
        $Worksheet = 1, 
         
        [parameter(mandatory=$false)] 
        [switch] 
        $Force 
    ) 
 
    Begin 
    { 
        function GetTempFileName($extension) 
        { 
            $temp = [io.path]::GetTempFileName(); 
            $params = @{ 
                Path = $temp; 
                Destination = $temp + $extension; 
                Confirm = $false; 
                Verbose = $VerbosePreference; 
            } 
            Move-Item @params; 
            $temp += $extension; 
            return $temp; 
        } 
             
        # since an extension like .xls can have multiple formats, this 
        # will need to be changed 
        # 
        $xlFileFormats = @{ 
            # single worksheet formats 
            '.csv'  = 6;        # 6, 22, 23, 24 
            '.dbf'  = 11;       # 7, 8, 11 
            '.dif'  = 9;        #  
            '.prn'  = 36;       #  
            '.slk'  = 2;        # 2, 10 
            '.wk1'  = 31;       # 5, 30, 31 
            '.wk3'  = 32;       # 15, 32 
            '.wk4'  = 38;       #  
            '.wks'  = 4;        #  
            '.xlw'  = 35;       #  
             
            # multiple worksheet formats 
            '.xls'  = -4143;    # -4143, 1, 16, 18, 29, 33, 39, 43 
            '.xlsb' = 50;       # 
            '.xlsm' = 52;       # 
            '.xlsx' = 51;       # 
            '.xml'  = 46;       # 
            '.ods'  = 60;       # 
        } 
         
        $xl = New-Object -ComObject Excel.Application; 
        $xl.DisplayAlerts = $false; 
        $xl.Visible = $false; 
    } 
 
    Process 
    { 
        $Path | ForEach-Object { 
             
            if ($Force -or $psCmdlet.ShouldProcess($_)) { 
             
                $fileExist = Test-Path $_ 
 
                if (-not $fileExist) { 
                    Write-Error "Error: $_ does not exist" -Category ResourceUnavailable;             
                } else { 
                    # create temporary .csv file from excel file and import .csv 
                    # 
                    $_ = (Resolve-Path $_).toString(); 
                    $wb = $xl.Workbooks.Add($_); 
                    if ($?) { 
                        $csvTemp = GetTempFileName(".csv"); 
                        $ws = $wb.Worksheets.Item($Worksheet); 
                        $ws.SaveAs($csvTemp, $xlFileFormats[".csv"]); 
                        $wb.Close($false); 
                        Remove-Variable -Name ('ws', 'wb') -Confirm:$false; 
                        Import-Csv $csvTemp; 
                        Remove-Item $csvTemp -Confirm:$false -Verbose:$VerbosePreference; 
                    } 
                } 
            } 
        } 
    } 
    
    End 
    { 
        $xl.Quit(); 
        Remove-Variable -name xl -Confirm:$false; 
        [gc]::Collect(); 
    } 
} 


function stage()
{
    [string]$date = ([string]$date = Get-Date) | % {$_ -replace("/", "_") } | % {$_ -replace(" ", "_")} |  % {$_ -replace(":", "_")}
    $global:outpath="D:\Week 5\$date"
    mkdir "$global:outpath\Volatility"
    mkdir "$global:outpath\Wireshark\PCAPs"
    mkdir "$global:outpath\Netflow"
    mkdir "$global:outpath\Snort"
    mkdir "$global:outpath\Malware"
}

function get_ip()
{
    $user_ips = Read-Host "Please enter the IPs that you would like to search for comma delimted (EX. 192.1.1.1, 192.1.2.1): "
    $parse = $user_ips -split ","
    $parse = $parse -replace '\s',''
    return $parse
}

function read_csv($csv_source)
{
    $csv_file = Import-Csv $csv_source
    return $csv_file
}

function make_utc($timevalue, $offset)
{
    
    $temptime = [datetime]$timevalue
    $temptime = $temptime.addhours($offset)
    return [string]$temptime
}

function get_header($csv)
{
    $csv_header = $csv | get-member |Where-Object {$_.MemberType -eq "NoteProperty"} | select-object Name
    return $csv_header
}

function csv_parser($csv_file, $ip_list)
{
    $ip_src_matches = @()
    $ip_dst_matches = @()
    $ip_two_degree_matches = @()
    $master_ip_list = @()
    $two_degrees
    foreach ($csv in $csv_file)
    {
        if($ip_list.contains($csv.'Source IP address'))
        {
            $ip_src_matches += $csv
            $two_degrees = $csv.'Destination IP address'
        }
        elseif($ip_list.contains($csv.'Destination IP address'))
        {
            $ip_dst_matches += $csv
            $two_degrees = $csv.'Source IP address'
        }

        if($two_degrees)
        {
            if($two_degrees.contains($csv.'Source IP address') -or $two_degrees.contains($csv.'Destination IP address'))
            {
                $ip_two_degree_matches += $csv
            }
        }  
    }
    
    $master_ip_list = $ip_src_matches+$ip_dst_matches+$ip_two_degree_matches
    $master_ip_list = $master_ip_list | sort 'Source IP address','Destination IP address','Flow Start Time','Flow End Time' -Unique
    $match_array = ($ip_src_matches, $ip_dst_matches, $ip_two_degree_matches, $master_ip_list)
    return $match_array
}

function make_sheet($worksheet, $list)
{
    $wsHeader = $null
    if(!$wsHeader)
    {
	$wsHeader = get_header($list)
    $wsColumns = 1
	#foreach ($header in $wsHeader)
	#{
            $wsColumns = 1
            $worksheet.Cells.Item($global:wsRows,$wsColumns) = "Flow Start Time"; $wsColumns++;
            $worksheet.Cells.Item($wsRows,$wsColumns) = "UTC Start Time"; $wsColumns++;
            $worksheet.Cells.Item($global:wsRows,$wsColumns) = "Flow End Time"; $wsColumns++;
            $worksheet.Cells.Item($wsRows,$wsColumns) = "UTC End Time"; $wsColumns++;
            $worksheet.Cells.Item($global:wsRows,$wsColumns) = "Flow Duration"; $wsColumns++;
            $worksheet.Cells.Item($global:wsRows,$wsColumns) = "Source IP"; $wsColumns++;
            $worksheet.Cells.Item($global:wsRows,$wsColumns) = "Destination IP"; $wsColumns++;
            $worksheet.Cells.Item($global:wsRows,$wsColumns) = "Source Port"; $wsColumns++;
            $worksheet.Cells.Item($global:wsRows,$wsColumns) = "Destination Port"; $wsColumns++;
            $worksheet.Cells.Item($global:wsRows,$wsColumns) = "Protocol"; $wsColumns++;
            $worksheet.Cells.Item($global:wsRows,$wsColumns) = "Flags"; $wsColumns++;
            $worksheet.Cells.Item($global:wsRows,$wsColumns) = "Forwarding Status"; $wsColumns++;
            $worksheet.Cells.Item($global:wsRows,$wsColumns) = "Source Type of Service"; $wsColumns++;
            $worksheet.Cells.Item($global:wsRows,$wsColumns) = "Input Packets"; $wsColumns++;
            $worksheet.Cells.Item($global:wsRows,$wsColumns) = "Input Bytes"; $global:wsRows++;
	#}
	$wsHeader = $true
    }
    foreach($ip in $list)
    {
        $wsColumns = 1
        $worksheet.Cells.Item($global:wsRows,$wsColumns) = $ip.'Flow Start Time'; $wsColumns++;
	    $worksheet.Cells.Item($wsRows,$wsColumns) = make_utc $ip.'Flow Start Time' $global:offset; $wsColumns++;
        $worksheet.Cells.Item($global:wsRows,$wsColumns) = $ip.'Flow End Time'; $wsColumns++;
        $worksheet.Cells.Item($wsRows,$wsColumns) = make_utc $ip.'Flow End Time' $global:offset; $wsColumns++;
        $worksheet.Cells.Item($global:wsRows,$wsColumns) = $ip.'Flow Duration'; $wsColumns++;
        $worksheet.Cells.Item($global:wsRows,$wsColumns) = $ip.'Source IP address'; $wsColumns++;
        $worksheet.Cells.Item($global:wsRows,$wsColumns) = $ip.'Destination IP address'; $wsColumns++;
        $worksheet.Cells.Item($global:wsRows,$wsColumns) = $ip.'Source Port'; $wsColumns++;
        $worksheet.Cells.Item($global:wsRows,$wsColumns) = $ip.'Destination Port'; $wsColumns++;
        $worksheet.Cells.Item($global:wsRows,$wsColumns) = $ip."Protocol"; $wsColumns++;
        $worksheet.Cells.Item($global:wsRows,$wsColumns) = $ip."Flags"; $wsColumns++;
        $worksheet.Cells.Item($global:wsRows,$wsColumns) = $ip."Forwarding Status"; $wsColumns++;
        $worksheet.Cells.Item($global:wsRows,$wsColumns) = $ip."Source Type of Service"; $wsColumns++;
        $worksheet.Cells.Item($global:wsRows,$wsColumns) = $ip."Input Packets"; $wsColumns++;
        $worksheet.Cells.Item($global:wsRows,$wsColumns) = $ip."Input Bytes"; $global:wsRows++;
        
    }
    $columns = $worksheet.Columns
    $columns.Item(1).hidden = $true
    $columns.Item(3).hidden = $true
    $wsrange = $worksheet.Range("a1","m1")
    $wsrange.AutoFilter() | Out-Null
    return $worksheet
}

function excel_export($master)
{
    
    $iXL = New-Object -ComObject Excel.Application
    $workbook = $iXL.WorkBooks.add()
    $worksheet1 = $workbook.Worksheets.Add()
    $worksheet1.name = "Two Degree Match"
    $worksheet2 = $workbook.Worksheets.Add()
    $worksheet2.name = "Dest IP Match"
    $worksheet3 = $workbook.Worksheets.Add()
    $worksheet3.name = "Source IP Match"
    $worksheet4 = $workbook.Worksheets.Add()
    $worksheet4.name = "MasterList"
    $iXL.Visible=$true
    $Global:wsRows = 1
    $worksheet1 = make_sheet $worksheet1 $master[3]  #3 is two degree
    $Global:wsRows = 1
    $worksheet2 = make_sheet $worksheet2 $master[2] #2 is dest
    $Global:wsRows = 1
    $worksheet3 = make_sheet $worksheet3 $master[1] #1 is source
    $Global:wsRows = 1
    $worksheet4 = make_sheet $worksheet4 $master[4] #4 is master list uniq

    $workbook.SaveAs("$global:outpath\Netflow\netflow_filtered.xlsx")
    $iXL.Quit()
    Clear-Variable iXL
    
}

function get_indicators($master)
{
    $iplist = @()
    foreach($value in $master)
    {
        $iplist += $value.'Destination IP address'
        $iplist += $value.'Source IP address'
    }
    $iplist = $iplist | sort -Unique
    return $iplist
}

function vol_scan($memfile, $indications)
{
    D:
    cd 'D:\Week 5\volatility_standalone'
    $global:imageinfo = .\volatility.exe -f $memfile imageinfo
    $global:profile =   (($global:imageinfo | Select-String "Suggested" | % { $_ -split ","})[1] | % { $_ -replace("\s", "")}) 
    $global:kdbg = (($global:imageinfo | Select-String "KDBG" | % { $_ -split ":"})[1] | % { $_ -replace("\s", "")} | % { $_ -replace("L", "")})
    .\volatility.exe -f $memfile --profile=$global:profile --kdbg=$global:kdbg pstree --output=xlsx --output-file="$global:outpath\Volatility\pstree.xlsx"
    .\volatility.exe -f $memfile --profile=$global:profile --kdbg=$global:kdbg psscan --output=xlsx --output-file="$global:outpath\Volatility\psscan.xlsx"
    .\volatility.exe -f $memfile --profile=$global:profile --kdbg=$global:kdbg psxview --output=xlsx --output-file="$global:outpath\Volatility\psxview.xlsx"
    .\volatility.exe -f $memfile --profile=$global:profile --kdbg=$global:kdbg netscan --output=xlsx --output-file="$global:outpath\Volatility\netscan.xlsx"
    .\volatility.exe -f $memfile --profile=$global:profile --kdbg=$global:kdbg malfind --output=xlsx --output-file="$global:outpath\Volatility\malfind.xlsx"
    #make yara_file here have function return filepath ip_12_12_12_12 is format to use
    foreach ($indicator in $indications)
    {
         .\volatility.exe -f $memfile --profile=$global:profile --kdbg=$global:kdbg yarascan --yara-rules=$indicator --output=xlsx --output-file="$global:outpath\Volatility\yara_$indicator.xlsx"
         #.\volatility.exe -f $memfile --profile=$global:profile --kdbg=$global:kdbg yarascan --y $yara_rule_file --output=xlsx --output-file="$global:outpath\Volatility\yara_$indicator.xlsx"
    }
}

function get_fileName()
{   
 [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
 $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
 #$OpenFileDialog.initialDirectory = $initialDirectory
 $OpenFileDialog.filter = "All files (*.*)| *.*"
 $OpenFileDialog.ShowDialog() | Out-Null
 return $OpenFileDialog.filename
} 
<#
function get_malware($memfile, $yara_dir)
{    
    $yara_master
    $yara_files = (ls $yara_dir\yara*.xlsx | % {$_.Name})
    foreach($file in $yara_files){$yara_master += Import-Xls "$yara_dir\$file"}
    $inc=0; $inc2 = 1;
    $yara_parser = $yara_master | %{ $_.Owner }
    $global:process_name = @(); $global:yara_pid = @()
    $yara_parser | foreach($process in $_){$global:process_name += $yara_parser[$inc];$inc+=2}
    foreach($process in $yara_parser){$global:yara_pid += $yara_parser[$inc2];$inc2+=2}

}#>

function pcap_filter($pcap_path, $indications)
{
    D:
    cd 'D:\Week 5'
    foreach($indication in $indications)
    {
        $path = "$global:outpath\Wireshark\PCAPs\$indication filter.pcap"
        .\WinDump.exe -n -r $pcap_path -w $path host $indication 
    }
}

function snort($pcap_path)
{
    C:
    cd "C:\snort\bin"
    .\snort.exe -r $pcap_path -c C:\Snort\etc\snort.conf -l C:\Snort\log -yU
    move C:\Snort\log\alert.csv $global:outpath\Snort\alert.csv
}


function GUI()
{

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    

    #$background = [system.drawing.image]::FromFile("C:\Users\Administrator\Pictures\background1.jpg") 
    


    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Powershell Function GUI"
    $form.Size = New-Object System.Drawing.Size(470, 300)
    $form.StartPosition = "CenterScreen"
    $form.BackgroundImage = $background
    

    $form.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
        {$form.Close()}})
    $form.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
        {$form.Close()}})
            

    $memForm = New-Object System.Windows.Forms.TextBox
    $memForm.Size = New-Object System.Drawing.Size(250, 25)
    $memForm.Location = New-Object System.Drawing.Size(30,20)
    $memForm.Text = "Enter the Path to your Memory Image file "
    $form.Controls.Add($memForm)

    $memButton = New-Object System.Windows.Forms.Button
    $memButton.Size = New-Object System.Drawing.Size(100, 25)
    $memButton.Location = New-Object System.Drawing.Size(325,20)
    $memButton.Add_Click{$global:memPath = get_fileName; $memForm.Text = $global:memPath}
    $memButton.Text = "Browse"
    $form.Controls.Add($memButton)

    $pcapForm = New-Object System.Windows.Forms.TextBox
    $pcapForm.Size = New-Object System.Drawing.Size(250, 25)
    $pcapForm.Location = New-Object System.Drawing.Size(30,65)
    $pcapForm.Text = "Enter the Path to your PCAP file "
    $form.Controls.Add($pcapForm)

    $pcapButton = New-Object System.Windows.Forms.Button
    $pcapButton.Size = New-Object System.Drawing.Size(100, 25)
    $pcapButton.Location = New-Object System.Drawing.Size(325,65)
    $pcapButton.Add_Click{$global:pcapPath = get_fileName; $pcapForm.Text = $global:pcapPath}
    $pcapButton.Text = "Browse"
    $form.Controls.Add($pcapButton)

    $flowForm = New-Object System.Windows.Forms.TextBox
    $flowForm.Size = New-Object System.Drawing.Size(250, 30)
    $flowForm.Location = New-Object System.Drawing.Size(30,110)
    $flowForm.Text = "Enter the Path to your Netflow file "
    $form.Controls.Add($flowForm)

    $flowButton = New-Object System.Windows.Forms.Button
    $flowButton.Size = New-Object System.Drawing.Size(100, 30)
    $flowButton.Location = New-Object System.Drawing.Size(325,110)
    $flowButton.Add_Click{$global:netflowPath = get_fileName; $flowForm.Text = $global:netflowPath}
    $flowButton.Text = "Browse"
    $form.Controls.Add($flowButton)

    $ipForm = New-Object System.Windows.Forms.TextBox
    $ipForm.Size = New-Object System.Drawing.Size(250, 30)
    $ipForm.Location = New-Object System.Drawing.Size(30,165)
    $ipForm.Text = "Enter Bad IP CSV"
    $form.Controls.Add($ipForm)

    $offsetLabel = new-object System.Windows.Forms.Label
    $offsetLabel.Location = new-object System.Drawing.Size(325, 145) 
    $offsetLabel.size = new-object System.Drawing.Size(100,12) 
    $offsetLabel.Text = "UTC Offset"
    $form.Controls.Add($offsetLabel)

    $offsetBox = New-Object System.Windows.Forms.ComboBox
    $offsetBox.Location = New-Object System.Drawing.Size(325,165) 
    $offsetBox.Size = New-Object System.Drawing.Size(100,30) 
    $offsetBox.Height = 80
    [void] $offsetBox.Items.Add("+1")
    [void] $offsetBox.Items.Add("+2")
    [void] $offsetBox.Items.Add("+3")
    [void] $offsetBox.Items.Add("+4")
    [void] $offsetBox.Items.Add("+5")
    [void] $offsetBox.Items.Add("+6")
    [void] $offsetBox.Items.Add("+7")
    $form.Controls.Add($offsetBox) 

    $exitButton = New-Object System.Windows.Forms.Button
    $exitButton.Size = New-Object System.Drawing.Size(100, 30)
    $exitButton.Location = New-Object System.Drawing.Size(175, 200)
    $exitButton.Add_Click{$global:ip_frombox = $ipForm.Text; $global:offset = $offsetBox.SelectedItem.ToString(); $form.Close(); main }
    $exitButton.Text = "OK"
    $exitButton.BackColor = "Green"
    $form.Controls.Add($exitButton)

    $form.ShowDialog()
}

function main()
{
    $global:start = get-date
    stage


    $csvfile = read_csv($global:netflowPath)
    $ips = $global:ip_frombox#('174.129.50.106')#get_ip
    $master= csv_parser $csvfile $ips
    $potential_ioc_ips = get_indicators $master[4]
    excel_export $master
    snort $global:pcapPath
    pcap_filter $global:pcapPath $potential_ioc_ips
    vol_scan $global:memPath $potential_ioc_ips 
    
}

GUI