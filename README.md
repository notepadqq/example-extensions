# Example Extensions
Example extensions for Notepadqq

Each extension should be put within `~/.config/Notepadqq/extensions/`

## What to push

We prefer to keep `node_modules` checked in in git. Here's how (we assume your dependencies are already in `package.json`). [[†]](http://www.letscodejavascript.com/v3/blog/2014/03/the_npm_debacle)

  1. Make sure you've checked in any recent changes, then delete your `node_modules`
     directory (so you're starting fresh) and remove it from your `.gitignore` file
	 or equivalent (so you can check it in).

  2. Run these commands from your project root (replace the git commands if you're
     using a different tool):
  
         npm install --ignore-scripts    # Download modules without building them
         git add . && git commit -a      # Check in modules
         npm rebuild                     # Build the modules
         git status                      # Show the files created by the build (there might not be any)
		
  3. Add the new files to `.gitignore` (or equivalent) and check it in.
  
The same approach also works when installing or updating a new dependency, except you don't delete your `node_modules` directory.
