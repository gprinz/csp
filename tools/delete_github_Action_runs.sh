# Variables
TOKEN='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'
OWNER='gprinz'
REPO='csp'
PER_PAGE=100  # Max items per page as per GitHub API limit

# Function to get and delete runs
get_and_delete_runs() {
    PAGE=1
    while : ; do
        # Fetch workflow run IDs with pagination
        RUN_IDS=$(curl -s -H "Authorization: token $TOKEN" \
            "https://api.github.com/repos/$OWNER/$REPO/actions/runs?page=$PAGE&per_page=$PER_PAGE" | jq '.workflow_runs[].id')
        
        # Check if RUN_IDS is empty
        if [[ -z "$RUN_IDS" ]]; then
            echo "No more runs to process."
            break
        fi

        # Loop over each run ID and delete it
        for ID in $RUN_IDS; do
            echo "Deleting run ID $ID..."
            curl -s -X DELETE -H "Authorization: token $TOKEN" \
                "https://api.github.com/repos/$OWNER/$REPO/actions/runs/$ID"
        done

        ((PAGE++))  # Increment the page number
    done
}

# Start the deletion process
get_and_delete_runs