import           Data.List
import           Data.List.Split
import           Data.Sequence
import           Data.Maybe

main = do
  contents <- readFile "input"
  let memory = fromList . map toInt . splitOn "," . init $ contents
  let result =
        find (\(res, _, _) -> res == 19690720)
          . map
              (\(noun, verb) ->
                ( executeProgram 0 . update 1 noun . update 2 verb $ memory
                , noun
                , verb
                )
              )
          $ [ (x, y) | x <- [0 .. 100], y <- [0 .. 100] ]
  case result of
    Just (_, noun, verb) -> print (noun * 100 + verb)
    Nothing              -> print (-1)

executeProgram :: Int -> Seq Int -> Int
executeProgram instructionPointer memory
  | memory `index` instructionPointer == 1 = executeProgram
    (instructionPointer + 4)
    (add instructionPointer memory)
  | memory `index` instructionPointer == 2 = executeProgram
    (instructionPointer + 4)
    (mul instructionPointer memory)
  | head :< _ <- viewl memory = head

add :: Int -> Seq Int -> Seq Int
add instrictionPointer memory = update
  outAddress
  ((memory `index` inAddress1) + (memory `index` inAddress2))
  memory
 where
  outAddress = memory `index` (instrictionPointer + 3)
  inAddress1 = memory `index` (instrictionPointer + 1)
  inAddress2 = memory `index` (instrictionPointer + 2)

mul :: Int -> Seq Int -> Seq Int
mul instrictionPointer memory = update
  outAddress
  ((memory `index` inAddress1) * (memory `index` inAddress2))
  memory
 where
  outAddress = memory `index` (instrictionPointer + 3)
  inAddress1 = memory `index` (instrictionPointer + 1)
  inAddress2 = memory `index` (instrictionPointer + 2)

toInt :: String -> Int
toInt = read
