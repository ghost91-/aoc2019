import           Data.List.Split
import           Data.Sequence

main = do
  contents <- readFile "input"
  let memory =
        update 2 2
          . update 1 12
          . fromList
          . map toInt
          . splitOn ","
          . init
          $ contents
  let result = executeProgram 0 memory
  print result

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
