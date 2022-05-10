# Manual setup instructions

..for where I don't have automation (yet, or never will bother).

## ssh into termux

From https://glow.li/posts/run-an-ssh-server-on-your-android-with-termux/

In termux:

```sh
apt install openssh
sshd
ifconfig # to get ip
```

Remote:

`ssh <ip> -p 8022`

## Install various environments

Rust: `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`

Dotnet: `curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --channel Current`

Go: `golang-install.sh`
