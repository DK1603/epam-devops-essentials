#!/bin/bash

input_file="$1"  # Ensure this is your accounts.csv file
output_file="accounts_new.csv"  # Define the output file name

# Generate email counts based on names
awk -F, 'BEGIN {OFS=","}
    NR == 1 {next}  # Skip header row
    {
        # Split the name by spaces to get first and last names. Adjust $2 based on the actual column.
        n = split($3, parts, " ");
        # Generate email prefix: first letter of the first name and the full last name, all lowercase.
        emailPrefix = tolower(substr(parts[1], 1, 1) parts[n]);
        email = emailPrefix;
        emailCounts[email]++;
    }
    END {
        for (email in emailCounts) {
            print email, emailCounts[email];
        }
    }
' "$input_file" > email_count.csv

# Process the file with knowledge of email uniqueness
awk -v OFS=, '
    BEGIN {
        FS = OFS = ","
        # Load email counts
        while ((getline < "email_count.csv") > 0) {
            emailCounts[$1] = $2
        }
    }
    NR == 1 {
        for (i=1; i<=NF; i++) {
            tags2fldNrs[$i] = i
            fldNrs2tags[i] = $i
        }
        nf = NF
        print $0 # Print header
        next
    }
    {
        delete vals
        fldNr = 0
        concatenating = 0
        for (i=1; i<=NF; i++) {
            if (concatenating) {
                vals[fldNr] = vals[fldNr] FS $i
                if ($i ~ /"$/) {
                    concatenating = 0
                }
            } else {
                if ($i ~ /^".*"$/) {
                    vals[++fldNr] = $i
                } else if ($i ~ /^"/) {
                    concatenating = 1
                    vals[++fldNr] = $i
                } else {
                    vals[++fldNr] = $i
                }
            }
        }

        nameFldNr = tags2fldNrs["name"]
        emailFldNr = tags2fldNrs["email"]
        locationFldNr = tags2fldNrs["location_id"]

        # Format name with proper capitalization, including after hyphens
        n = split(vals[nameFldNr], nameParts, " ");
        formattedName = "";
        for (j = 1; j <= n; j++) {
            split(nameParts[j], subParts, "-");
            formattedSubPart = "";
            for (k = 1; k <= length(subParts); k++) {
                if (k > 1) formattedSubPart = formattedSubPart "-";
                formattedSubPart = formattedSubPart toupper(substr(subParts[k], 1, 1)) tolower(substr(subParts[k], 2));
            }
            if (j > 1) formattedName = formattedName " ";
            formattedName = formattedName formattedSubPart;
        }
        vals[nameFldNr] = formattedName;


        # Generate and format email considering uniqueness
        baseEmail = tolower(substr(nameParts[1], 1, 1)) tolower(nameParts[n])
        if (emailCounts[baseEmail] > 1) {
            email = baseEmail vals[locationFldNr] "@abc.com"
        } else {
            email = baseEmail "@abc.com"
        }
        vals[emailFldNr] = email

        # Output the modified record
        for (i = 1; i <= nf; i++) {
            printf "%s%s", vals[i], (i < nf ? OFS : ORS)
        }
    }
' "$input_file" > "$output_file"

echo "Processed file saved as $output_file"












