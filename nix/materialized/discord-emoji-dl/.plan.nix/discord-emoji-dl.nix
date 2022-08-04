{ system
  , compiler
  , flags
  , pkgs
  , hsPkgs
  , pkgconfPkgs
  , errorHandler
  , config
  , ... }:
  ({
    flags = {};
    package = {
      specVersion = "1.12";
      identifier = { name = "discord-emoji-dl"; version = "0.1.0.0"; };
      license = "NONE";
      copyright = "";
      maintainer = "Chua Hou <human+github@chuahou.dev>";
      author = "";
      homepage = "https://github.com/chuahou/discord-emoji-dl#readme";
      url = "";
      synopsis = "downloads Discord emoji as a bot";
      description = "Downloads all custom Discord emoji in a server as a bot.";
      buildType = "Simple";
      isLocal = true;
      detailLevel = "FullDetails";
      licenseFiles = [];
      dataDir = ".";
      dataFiles = [];
      extraSrcFiles = [];
      extraTmpFiles = [];
      extraDocFiles = [];
      };
    components = {
      exes = {
        "discord-emoji-dl" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."discord-haskell" or (errorHandler.buildDepError "discord-haskell"))
            ];
          buildable = true;
          modules = [ "Paths_discord_emoji_dl" ];
          hsSourceDirs = [ "exe" ];
          mainPath = [ "Main.hs" ];
          };
        };
      };
    } // rec { src = (pkgs.lib).mkDefault ../.; }) // {
    cabal-generator = "hpack";
    }