# Load the required .NET framework assemblies for the GUI
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore

# === YOUR WEB APP URL ===
$WebAppUrl = "https://script.google.com/macros/s/AKfycbylzTZlgIj-9_J8HH2JAQsqrmqrkRG-1vPVL4cWFbExuvXcU7wnbYlOIgrT3mS8Nc4f/exec" # UPDATE THIS TO YOUR ACTUAL URL

# 1. Define the UI using XAML (Dark Theme similar to your screenshot)
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="AnyDesk Facility Manager" Height="500" Width="650" Background="#1E1E1E" WindowStartupLocation="CenterScreen">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <TextBlock Text="COMTECH FACILITY CONNECTIONS" Foreground="#00A2ED" FontSize="18" FontWeight="Bold" Margin="0,0,0,10" HorizontalAlignment="Center"/>
        
        <!-- The Data Table -->
        <ListView Name="FacilityList" Grid.Row="1" Background="#2D2D30" Foreground="White" BorderBrush="#3E3E42" BorderThickness="1">
            <ListView.Resources>
                <Style TargetType="GridViewColumnHeader">
                    <Setter Property="Background" Value="#333337"/>
                    <Setter Property="Foreground" Value="White"/>
                    <Setter Property="Padding" Value="5"/>
                </Style>
            </ListView.Resources>
            <ListView.View>
                <GridView>
                    <GridViewColumn Header="Facility Name" DisplayMemberBinding="{Binding Facility}" Width="300"/>
                    <GridViewColumn Header="AnyDesk ID" DisplayMemberBinding="{Binding AnyDeskID}" Width="150"/>
                    <GridViewColumn Header="Status" DisplayMemberBinding="{Binding Status}" Width="100"/>
                </GridView>
            </ListView.View>
        </ListView>

        <!-- Bottom Controls -->
        <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,15,0,0">
            <Button Name="RefreshBtn" Content="Refresh Data" Width="120" Height="30" Margin="0,0,20,0" Background="#333337" Foreground="White" BorderBrush="#555"/>
            <TextBlock Name="StatusText" Text="Loading data..." Foreground="DarkGray" VerticalAlignment="Center" FontStyle="Italic"/>
        </StackPanel>
    </Grid>
</Window>
"@

# 2. Read the XAML and create the Window
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$Window = [Windows.Markup.XamlReader]::Load($reader)

# 3. Find the UI Elements we need to interact with
$FacilityList = $Window.FindName("FacilityList")
$RefreshBtn   = $Window.FindName("RefreshBtn")
$StatusText   = $Window.FindName("StatusText")

# 4. Function to Fetch and Load Data
function Load-Data {
    $StatusText.Text = "Fetching live data..."
    $Window.Dispatcher.Invoke([Action]{}, "Render") # Force UI to update

    try {
        $LiveUrl = "${WebAppUrl}?action=read&token=$(Get-Date -UFormat %s)"
        $AntiCacheHeaders = @{ "Cache-Control" = "no-cache"; "Pragma" = "no-cache" }
        
        $Data = Invoke-RestMethod -Uri $LiveUrl -Method Get -Headers $AntiCacheHeaders | Sort-Object -Property Facility
        
        $FacilityList.Items.Clear()
        foreach ($item in $Data) {
            # Add each row from Google Sheets into our GUI list
            [void]$FacilityList.Items.Add($item)
        }
        $StatusText.Text = "Last Updated: $(Get-Date -Format 'HH:mm:ss')"
    } catch {
        $StatusText.Text = "Connection Error!"
        $StatusText.Foreground = "Red"
    }
}

# 5. EVENT: Double-Click a Row to Launch AnyDesk
$FacilityList.Add_MouseDoubleClick({
    $SelectedRow = $FacilityList.SelectedItem
    if ($null -ne $SelectedRow) {
        $StatusText.Text = "Connecting to $($SelectedRow.Facility)..."
        
        # Clean the ID and launch AnyDesk just like your old script
        $CleanID = ([string]$SelectedRow.AnyDeskID).Replace(" ", "")
        cmd /c start "" "anydesk:$CleanID"
    }
})

# 6. EVENT: Click the Refresh Button
$RefreshBtn.Add_Click({
    Load-Data
})

# 7. Initial Data Load (Runs when the window opens)
$Window.Add_Loaded({
    Load-Data
})

# 8. Show the Window
[void]$Window.ShowDialog()