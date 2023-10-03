import unittest

import vslice

test "test full slice":
    let values = @[true, false, true, false]
    let slice = values.slice()

    doAssert slice.len == values.len
    doAssert $slice == "&[true, false, true, false]"
    doAssert slice == values

test "test partial slice":
    let values = [1, 2, 3, 4]
    let slice = values.slice(1..2)

    doAssert slice.len == 2
    doAssert $slice == "&[2, 3]"
    doAssert slice == values[1..2]

test "test reslice":
    let values = ["this", "is", "a", "test"]
    let slice = values.slice()[1..2]

    doAssert slice.len == 2
    echo $slice
    doAssert $slice == "&[is, a]"
    doAssert slice == values[1..2]

test "test full slice of string":
    let value = "this is a test"
    let slice = value.slice()

    doAssert slice.len == value.len
    doAssert $slice == value
    doAssert slice == value

test "test partial slice of string":
    let value = "this is a test"
    let slice = value.slice(5..8)

    doAssert slice.len == 4
    doAssert $slice == value[5..8]
    doAssert slice == value[5..8]

test "test reslice of a string":
    let value = "this is a test"
    let slice = value.slice()[5..8]

    doAssert slice.len == 4
    doAssert $slice == value[5..8]
    doAssert slice == value[5..8]
