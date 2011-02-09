------------------------------------------------------------------------------
--- Compiler options for the ID-based curry compiler
---
--- @author Fabian Reck, Björn Peemöller
--- @version February 2011
------------------------------------------------------------------------------
module CompilerOpts
  ( compilerOpts, Options (..), SearchMode (..), Dump (..)
  ) where

import IO (hPutStrLn, stderr)
import List (nub)
import Maybe (fromMaybe)
import System (exitWith, getArgs, getProgName)

import GetOpt

type Options =
  { optQuiet      :: Bool       -- quiet mode
  , optVersion    :: Bool       -- show version
  , optHelp       :: Bool       -- show usage
  , optSearchMode :: SearchMode -- search mode
  , optHoDetMode  :: Bool       -- deterministic higher order functions
  , dump          :: [Dump]     -- dump intermediate results
  }

data SearchMode
  = NoSearch -- no search
  | DFS      -- depth first search
  | BFS      -- bredth first search
  | IterDFS  -- iterative depth first search
  | PAR      -- parallel search

data Dump
  = DumpFlat        -- dump flat curry
  | DumpLifted      -- dump flat curry after case lifting
  | DumpAbstractHs  -- dump abstract Haskell

defaultOptions :: Options
defaultOptions =
  { optQuiet      = False
  , optVersion    = False
  , optHelp       = False
  , optSearchMode = NoSearch
  , optHoDetMode  = False
  , dump          = []
  }

options :: [OptDescr (Options -> Options)]
options =
  [ Option ['q'] ["quiet"]
      (NoArg (\opts -> { optQuiet   := True | opts }))
      "run in quiet mode"
  , Option ['v'] ["version"]
      (NoArg (\opts -> { optVersion := True | opts }))
      "show version number"
  , Option ['h'] ["help"]
      (NoArg (\opts -> { optHelp    := True | opts }))
      "show usage information"
  , Option ['s'] ["search-mode"]
      (ReqArg (\arg opts -> { optSearchMode := fromMaybe
        (opts -> optSearchMode) (lookup arg searchModes) | opts } )
      "SEARCHMODE")
      "set search mode, one of [DFS, BFS, IterDFS, PAR]"
  , Option [] ["HO"]
      (NoArg (\opts -> { optHoDetMode := True | opts } ))
      "enable deterministic higher-order functions"
  , Option [] ["dump-flat"]
      (NoArg (\opts -> { dump := nub (DumpFlat : opts -> dump) | opts }))
      "dump flat curry representation"
  , Option [] ["dump-lifted"]
      (NoArg (\opts -> { dump := nub (DumpLifted : opts -> dump) | opts }))
      "dump flat curry after case lifting"
  , Option [] ["dump-abstract-hs"]
      (NoArg (\opts -> { dump := nub (DumpAbstractHs : opts -> dump) | opts }))
      "dump abstract Haskell representation"
  , Option [] ["dump-all"]
      (NoArg (\opts -> { dump := [DumpFlat, DumpLifted, DumpAbstractHs] | opts }))
      "dump all intermediate results"
  ]

searchModes :: [(String, SearchMode)]
searchModes =
  [ ("DFS", DFS)
  , ("BFS", BFS)
  , ("IterDFS", IterDFS)
  , ("PAR", PAR)
  ]

versionString :: String
versionString = "ID-based Curry -> Haskell Compiler (Version of 09/02/11)"

parseOpts :: [String] -> (Options, [String], [String])
parseOpts args = (foldl (flip ($)) defaultOptions opts, files, errs)
  where (opts, files, errs) = getOpt Permute options args

checkOpts :: Options -> [String] -> [String]
checkOpts _ []    = ["no files"]
checkOpts _ (_:_) = []

printVersion :: IO a
printVersion = do
  putStrLn versionString
  exitWith 0

printUsage :: String -> IO a
printUsage prog = do
  putStrLn $ usageInfo header options
  exitWith 0
    where header = "usage: " ++ prog ++ " [OPTION] ... MODULE ..."

badUsage :: String -> [String] -> IO a
badUsage prog [] = do
  hPutStrLn stderr $ "Try '" ++ prog ++ " --help' for more information"
  exitWith 1
badUsage prog (err:errs) = hPutStrLn stderr err >> badUsage prog errs

compilerOpts :: IO (Options, [String])
compilerOpts = do
  args <- getArgs
  prog <- getProgName
  processOpts prog $ parseOpts args

processOpts :: String -> (Options, [String], [String]) -> IO (Options, [String])
processOpts prog (opts, files, errs)
  | opts -> optHelp    = printUsage prog
  | opts -> optVersion = printVersion
  | not (null errs')   = badUsage prog errs'
  | otherwise          = return (opts, files)
    where errs' = errs ++ checkOpts opts files
