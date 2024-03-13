param(
    [string] $file = "./accounts.csv"
)

# Converts Name to Proper Case
function Convert-Name([string] $name) {
    $parts = $name -split ' ' # Split name into parts
    for ($i = 0; $i -lt $parts.Length; $i++) {
        # Split further by hyphen if needed and capitalize each part
        $subParts = $parts[$i] -split '-'
        for ($j = 0; $j -lt $subParts.Length; $j++) {
            $subParts[$j] = $subParts[$j].Substring(0, 1).ToUpper() + $subParts[$j].Substring(1).ToLower()
        }
        # Rejoin sub-parts (if they were split by hyphen)
        $parts[$i] = $subParts -join '-'
    }
    # Rejoin parts and return
    return $parts -join ' '
}


# Create email in format flast_name{location_id}@abc.com
function Convert-Email([string] $name, [string] $location_id = "") {
    $first_name, $last_name = $name.Split(" ")
    $email = $first_name.Substring(0, 1) + $last_name + $location_id
    $email = $email.ToLower()
    return $email + "@abc.com"
}


# Check if $file exists
if ((Test-Path $file) -eq $false) {
    Throw "provided file doesn't exist"
}

# Extract directory to create accounts_new.csv
$directory = Split-Path $file

$records = Import-Csv $file

# Count number of same emails
[hashtable] $email_counter = @{}

foreach ($record in $records) {
    $email = Convert-Email $record.name
    $email_counter[$email]++
}

foreach ($record in $records) {
    $record.name = Convert-Name $record.name
    $record.email = Convert-Email $record.name
    # If there are more than 1 of the email, include location_id
    if ($email_counter[$record.email] -gt 1) {
        $record.email = Convert-Email $record.name $record.location_id
    }
}

$records | Export-Csv -UseQuotes AsNeeded $directory/accounts_new.csv