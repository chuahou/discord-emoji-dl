-- SPDX-License-Identifier: MIT
-- Copyright (c) 2022 Chua Hou

module Main (main) where

import Data.Default           qualified as Def
import Data.Foldable          (foldl')
import Data.Text              (Text)
import Data.Text              qualified as Text
import Data.Text.IO           qualified as TIO
import Data.Version           (showVersion)
import Discord                (DiscordHandler, RunDiscordOpts (..), runDiscord,
                               stopDiscord)
import Discord.Types          (GatewayIntent (..))
import Paths_discord_emoji_dl (version)
import System.Console.GetOpt  (ArgDescr (..), ArgOrder (..), OptDescr (..),
                               getOpt, usageInfo)
import System.Environment     (getArgs, getProgName)
import System.Exit            (exitFailure)
import System.IO              (hPutStrLn, stderr)
import Text.Read              (readMaybe)

data ProgOpts = ProgOpts { optToken :: Maybe (Either Text FilePath)
                         , optID    :: Maybe Int
                         , optHelp  :: Bool
                         , optVer   :: Bool
                         } deriving Show

instance Def.Default ProgOpts where
    def = ProgOpts { optToken = Nothing
                   , optID    = Nothing
                   , optHelp  = False
                   , optVer   = False
                   }

progOpts :: [OptDescr (ProgOpts -> ProgOpts)]
progOpts =
    [ Option ['t'] ["token"]
        (ReqArg (\x o -> o { optToken = Just (Left . Text.pack $ x) }) "TOKEN")
        "Discord bot token"
    , Option ['f'] ["token-file"]
        (ReqArg (\x o -> o { optToken = Just (Right x) }) "FILENAME")
        "Discord bot token in file"
    , Option ['s'] ["server"]
        (ReqArg (\x o -> o { optID = readMaybe x }) "SERVER ID")
        "Server ID of server to download emoji from"
    , Option ['h', '?'] ["help"]
        (NoArg (\o -> o { optHelp = True })) "Print this usage message"
    , Option ['v'] ["print-version"]
        (NoArg (\o -> o { optVer = True })) "Print program version"
    ]

main :: IO ()
main = do
    argv <- getArgs
    case getOpt Permute progOpts argv of
      (o, [], []) -> runBot $ foldl' (flip ($)) Def.def o
      (_,  _, es) -> printUsage $ concat es
    where
        printUsage :: String -> IO ()
        printUsage errMsg = do
            progName <- getProgName
            hPutStrLn stderr (errMsg ++ usageInfo
                ("Usage: " ++ progName ++ " [OPTIONS]") progOpts)
            exitFailure

        printVersion :: IO ()
        printVersion = do
            progName <- getProgName
            putStrLn $ progName ++ " " ++ showVersion version

        runBot :: ProgOpts -> IO ()
        runBot opts
            | optHelp opts = printUsage ""
            | optVer opts = printVersion
            | otherwise =
                case (,) <$> optToken opts <*> optID opts of
                  Nothing -> printUsage "A bot token and server ID must be specified"
                  Just (et, sid) -> do
                      tok <- either pure TIO.readFile et
                      err <- runDiscord $ Def.def
                                { discordToken = tok
                                , discordGatewayIntent = GatewayIntent
                                    { gatewayIntentGuilds = False
                                    , gatewayIntentMembers = False
                                    , gatewayIntentBans = False
                                    , gatewayIntentEmojis = True -- true
                                    , gatewayIntentIntegrations = False
                                    , gatewayIntentWebhooks = False
                                    , gatewayIntentInvites = False
                                    , gatewayIntentVoiceStates = False
                                    , gatewayIntentPrecenses = False
                                    , gatewayIntentMessageChanges = False
                                    , gatewayIntentMessageReactions = False
                                    , gatewayIntentMessageTyping = False
                                    , gatewayIntentDirectMessageChanges = False
                                    , gatewayIntentDirectMessageReactions = False
                                    , gatewayIntentDirectMessageTyping = False
                                    , gatewayIntentMessageContent = False
                                    }
                                , discordOnStart = discordMain sid
                                }
                      TIO.hPutStrLn stderr err

-- | Main entry point for Discord operations.
discordMain :: Int -> DiscordHandler ()
discordMain sid = do
    stopDiscord
