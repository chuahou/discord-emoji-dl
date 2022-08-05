-- SPDX-License-Identifier: MIT
-- Copyright (c) 2022 Chua Hou

module Main (main) where

import Control.Monad.IO.Class (liftIO)
import Data.ByteString.Lazy   qualified as LBS
import Data.Default           qualified as Def
import Data.Foldable          (foldl', traverse_)
import Data.Text              (Text)
import Data.Text              qualified as Text
import Data.Text.IO           qualified as TIO
import Data.Version           (showVersion)
import Discord                (DiscordHandler, RunDiscordOpts (..), restCall,
                               runDiscord, stopDiscord)
import Discord.Requests       (EmojiRequest (..))
import Discord.Types          (Emoji (..), GatewayIntent (..))
import Network.HTTP.Simple    (getResponseBody, httpLBS, parseRequest)
import Paths_discord_emoji_dl (version)
import System.Console.GetOpt  (ArgDescr (..), ArgOrder (..), OptDescr (..),
                               getOpt, usageInfo)
import System.Directory       (createDirectoryIfMissing)
import System.Environment     (getArgs, getProgName)
import System.Exit            (exitFailure)
import System.FilePath        ((<.>), (</>))
import System.IO              (hPrint, hPutStrLn, stderr)
import System.IO.Error        (tryIOError)
import Text.Read              (readMaybe)

data ProgOpts = ProgOpts { optToken  :: Maybe (Either Text FilePath)
                         , optID     :: Maybe Int
                         , optHelp   :: Bool
                         , optVer    :: Bool
                         , optOutDir :: FilePath
                         } deriving Show

instance Def.Default ProgOpts where
    def = ProgOpts { optToken  = Nothing
                   , optID     = Nothing
                   , optHelp   = False
                   , optVer    = False
                   , optOutDir = "."
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
    , Option ['o'] ["out-dir"]
        (ReqArg (\x o -> o { optOutDir = x }) "PATH")
        "Output directory, defaults to pwd"
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
            | otherwise = do
                createDirectoryIfMissing True $ optOutDir opts
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
                                , discordOnStart = discordMain sid (optOutDir opts)
                                }
                      TIO.hPutStrLn stderr err

-- | Main entry point for Discord operations.
discordMain :: Int -> FilePath -> DiscordHandler ()
discordMain serverId outDir = do
    restCall (ListGuildEmojis (fromIntegral serverId)) >>= \case
        Left err     -> liftIO $ hPrint stderr err
        Right emojis -> liftIO $ traverse_ saveEmoji emojis
    stopDiscord

    where
        saveEmoji :: Emoji -> IO ()
        saveEmoji e =
            case emojiId e of
              Nothing -> hPutStrLn stderr $ show e ++ " has no emoji ID, skipping."
              Just eid ->
                  let ext = case emojiAnimated e of
                              Just True -> ".gif"
                              _         -> ".webp"
                      outPath = outDir </> Text.unpack (emojiName e) <.> ext
                   in download outPath $ concat
                        [ "https://cdn.discordapp.com/emojis/", show eid, ext ]
        download :: FilePath -> String -> IO ()
        download out url = either printErr pure =<< tryIOError (do
            req <- parseRequest url
            resp <- httpLBS req
            LBS.writeFile out $ getResponseBody resp
            hPutStrLn stderr $ "Downloaded " ++ out)
                where
                    printErr :: IOError -> IO ()
                    printErr err = do
                        hPrint stderr err
                        hPutStrLn stderr $ "Was unable to download from " ++ url
