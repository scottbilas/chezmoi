* Move non-config stuff out of .config/etc. to some off-root "resources" or whatev
* Migrate remaining stuff into chezmoi
* Replace dotfiles with chezmoi
  * Tag dotfiles head to mark pre-repave state and keep it from getting collected
  * Delete everything in dotfiles
  * Pull in chezmoi to a separate branch to pick up full history
  * Reset branch to chezmoi stuff
  * Clean out old branches
  * Nuke chezmoi
* Integrate chezmoi status into ~ prompt
