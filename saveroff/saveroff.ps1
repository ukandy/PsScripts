

$xaml = @'

<Window
   xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
   xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
   Width="525"
   SizeToContent="Height"
   Title="Saver Off" Topmost="True" Height="228">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <Button x:Name="Exit" Width="80" Height="25" Grid.Row="1"  HorizontalAlignment="Right" Margin="5" VerticalAlignment="Bottom" Content="Exit"/>
        <Button x:Name="Saveroff" Content="Disable Saver" HorizontalAlignment="Left" Margin="24,26,0,0" VerticalAlignment="Top" Width="219" Height="30"/>
        <Button x:Name="saveron" Content="Re Enable Saver" HorizontalAlignment="Left" Margin="277,26,0,0" VerticalAlignment="Top" Width="219" Height="30"/>
        <Label x:Name="status" Content="Saver is Enabled" HorizontalAlignment="Left" Height="52" Margin="24,89,0,0" VerticalAlignment="Top" Width="472" FontSize="24" />
    </Grid>
</Window>

'@

function Convert-XAMLtoWindow
{
    param
    (
        [Parameter(Mandatory=$true)]
        [string]
        $XAML
    )
    
    Add-Type -AssemblyName PresentationFramework
    
    $reader = [XML.XMLReader]::Create([IO.StringReader]$XAML)
    $result = [Windows.Markup.XAMLReader]::Load($reader)
    $reader.Close()
    $reader = [XML.XMLReader]::Create([IO.StringReader]$XAML)
    while ($reader.Read())
    {
        $name=$reader.GetAttribute('Name')
        if (!$name) { $name=$reader.GetAttribute('x:Name') }
        if($name)
        {$result | Add-Member NoteProperty -Name $name -Value $result.FindName($name) -Force}
    }
    $reader.Close()
    $result
}


function Show-WPFWindow
{
    param
    (
        [Parameter(Mandatory)]
        [Windows.Window]
        $Window
    )
    
    $result = $null
    $null = $window.Dispatcher.InvokeAsync{
        $result = $window.ShowDialog()
        Set-Variable -Name result -Value $result -Scope 1
    }.Wait()
    $result
}


   $code=@' 
[DllImport("kernel32.dll", CharSet = CharSet.Auto,SetLastError = true)]
  public static extern void SetThreadExecutionState(uint esFlags);
'@

    $ste = Add-Type -memberDefinition $code -name System -namespace Win32 -passThru 
    $ES_CONTINUOUS = [uint32]"0x80000000" #Requests that the other EXECUTION_STATE flags set remain in effect until SetThreadExecutionState is called again with the ES_CONTINUOUS flag set and one of the other EXECUTION_STATE flags cleared.
    $ES_AWAYMODE_REQUIRED = [uint32]"0x00000040" #Requests Away Mode to be enabled.
    $ES_DISPLAY_REQUIRED = [uint32]"0x00000002" #Requests display availability (display idle timeout is prevented).
    $ES_SYSTEM_REQUIRED = [uint32]"0x00000001" #Requests system availability (sleep idle timeout is prevented).

    $setting = "display"

    Switch ($option)
    {
      "Away" {$setting = $ES_AWAYMODE_REQUIRED}
      "Display" {$setting = $ES_DISPLAY_REQUIRED}
      "System" {$setting = $ES_SYSTEM_REQUIRED}
      Default {$setting = $ES_SYSTEM_REQUIRED}

    }


$window = Convert-XAMLtoWindow -XAML $xaml



$window.Exit.add_Click{
    $window.DialogResult = $true
    $NoFormExit = $False
    $ste::SetThreadExecutionState($ES_CONTINUOUS)
    $Window.Close()
}



$window.Saveroff.add_click{
  write-host "off"
    
  $ste::SetThreadExecutionState($ES_CONTINUOUS -bor $setting)
  $window.status.Content = "Saver is off"
  
}


$window.saveron.add_click{

  write-host "on"
   $ste::SetThreadExecutionState($ES_CONTINUOUS)
   $window.status.Content = "Saver is on as normal"

}



#Catch clicking of Form CloseBox
  $Window.Add_Closing({param($Sender,$ExitForm)
      
      write-host "hello"
      $ste::SetThreadExecutionState($ES_CONTINUOUS)
      
       
  })



$null = Show-WPFWindow -Window $window

