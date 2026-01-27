#!/usr/bin/env nu
# Initialize git repositories for AdaptiveCPP package
# Reads .repos.toml and clones missing repositories (shallow)

def main [] {
    # Get the directory containing this script
    let script_dir = ($env.CURRENT_FILE | path dirname)
    let package_dir = ($script_dir | path dirname)
    let repos_config = ($package_dir | path join ".repos.toml")
    
    # Verify .repos.toml exists
    if not ($repos_config | path exists) {
        print $"Error: Configuration file not found at ($repos_config)"
        exit 1
    }
    
    # Parse .repos.toml
    let config = (open $repos_config)
    
    print "=" 
    print "Initializing repositories for AdaptiveCPP package"
    print $"Config: ($repos_config)"
    print "="
    
    # Process each repository
    for repo in ($config.repos | transpose name details) {
        let repo_name = $repo.name
        let repo_url = $repo.details.url
        let repo_branch = $repo.details.branch
        let repo_path = ($package_dir | path join $repo.details.path)
        
        print ""
        print $"[($repo_name)]"
        print $"  URL: ($repo_url)"
        print $"  Branch: ($repo_branch)"
        print $"  Path: ($repo_path)"
        
        # Check if repository directory exists
        if ($repo_path | path exists) {
            # Verify it's a git repository
            let git_dir = ($repo_path | path join ".git")
            if not ($git_dir | path exists) {
                print $"Error: Directory exists but is not a git repository: ($repo_path)"
                print "Please remove the directory and run this command again"
                exit 1
            }
            
            # Verify remote URL matches
            cd $repo_path
            let current_remote = (git remote get-url origin | str trim)
            
            if $current_remote != $repo_url {
                print $"Error: Repository exists with wrong remote URL"
                print $"  Expected: ($repo_url)"
                print $"  Found:    ($current_remote)"
                print $"  Location: ($repo_path)"
                print ""
                print "To fix: Remove the directory and run this command again"
                exit 1
            }
            
            print "  Status: OK (already exists)"
        } else {
            # Clone repository (shallow)
            print "  Status: Cloning (shallow)..."
            git clone --depth 1 --branch $repo_branch $repo_url $repo_path
            
            if $env.LAST_EXIT_CODE != 0 {
                print $"Error: Failed to clone ($repo_name)"
                exit 1
            }
            
            print "  Status: OK (cloned)"
        }
    }
    
    print ""
    print "=" 
    print "All repositories initialized successfully!"
    print "="
}

main
