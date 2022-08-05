# discord-emoji-dl

Downloads Discord emoji as a bot. Using a bot token, it lists all custom emoji
present in the server and downloads them locally as `.webp` or `.gif` files.
This makes them suitable for use in other servers or on other platforms.

## Building

The usual Haskell way works with `cabal build` and
`cabal run -- exe:discord-emoji-dl [args]`, and Nix using the
[haskell.nix](https://github.com/input-output-hk/haskell.nix) way.

## Usage

At minimum, a token needs to be provided either as a commandline argument or in
a file containing exactly the token text, as well as a server ID (right-click on
the server icon and choose "Copy ID" in the context menu).

    Usage: discord-emoji-dl [OPTIONS]
      -t TOKEN      --token=TOKEN          Discord bot token
      -f FILENAME   --token-file=FILENAME  Discord bot token in file
      -s SERVER ID  --server=SERVER ID     Server ID of server to download emoji from
      -o PATH       --out-dir=PATH         Output directory, defaults to pwd
      -h, -?        --help                 Print this usage message
      -v            --print-version        Print program version

## Example

    discord-emoji-dl -f tokenFile -s 123456789123456789 -o outputDirectory
