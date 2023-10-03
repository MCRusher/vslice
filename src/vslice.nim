import streams

type VSlice*[T] = object
    ## a value-based slice as opposed to the stdlib Slice/HSlice
    ## 
    ## note: vslices are non-owning references
    data*: ptr UncheckedArray[T]
    len*: int

type StringVSlice* {.borrow: `.`.} = distinct VSlice[char] ## \
    ## a specialized form of VSlice that deals with a slice of a string
    ## 
    ## note: stringvslices are non-owning references

converter toVSlice*(svs: StringVSlice): VSlice[char] {.inline.} =
    ## convert a StringVSlice to a VSlice[char]
    VSlice[char](svs)

proc `[]`*[T](vs: VSlice[T], index: Natural): lent T {.inline, noSideEffect.} =
    ## index a slice
    assert index < vs.len

    vs.data[index]

proc `[]`*[T](vs: VSlice[T], s: Slice[int]): VSlice[T] {.inline, noSideEffect.} =
    ## reslice a slice
    #assert s.b - s.a < vs.len
    assert s.a < vs.len and s.b < vs.len

    VSlice[T](data: cast[ptr UncheckedArray[T]](vs.data[s.a].addr), len: (s.b - s.a + 1))

proc `[]`*(svs: StringVSlice, s: Slice[int]): StringVSlice {.inline, noSideEffect.} =
    ## reslice a string slice
    VSlice[char](svs)[s].StringVSlice

iterator items*[T](vs: VSlice[T]): T {.inline.} =
    for i in 0..vs.len-1:
        yield vs.data[i]

proc `$`*[T](vs: VSlice[T]): string {.noSideEffect.} =
    ## stringize a vslice (allocates a new string)
    result = "&["
    for i in 0..vs.len-1:
        result &= $vs.data[i]
        if i < vs.len-1:
            result &= ", "
    result &= ']'

proc `$`*(svs: StringVSlice): string {.noSideEffect.} =
    ## stringize a string vslice (allocates a new string)
    result = newString(svs.len)
    if svs.len > 0:
        copyMem(result[0].addr, svs.data, svs.len)

converter toString*(svs: StringVSlice): string {.inline.} = $svs ## \
    ## implicit conversion to string

func slice*[T](arr: openArray[T], start: Natural, len: Positive): VSlice[T] {.inline.} =
    ## create a value slice of an array
    assert len - start <= arr.len

    VSlice[T](data: cast[ptr UncheckedArray[T]](arr[start].addr), len: len)

# need a separate function instead of default args since it magically breaks codegen for some reason
func slice*[T](arr: openArray[T]): VSlice[T] {.inline.} =
    arr.slice(0, arr.len)

func slice*[T](arr: openArray[T], s: Slice[T]): VSlice[T] {.inline.} =
    slice(arr, s.a, (s.b - s.a) + 1)

func slice*(str: string, start: Natural, len: Positive): StringVSlice {.inline.} =
    ## create a value slice of a string
    assert len - start <= str.len

    VSlice[char](data: cast[ptr UncheckedArray[char]](str[start].addr), len: len).StringVSlice

func slice*(str: string): StringVSlice {.inline.} =
    str.slice(0, str.len)

func slice*(str: string, s: Slice[int]): StringVSlice {.inline.} =
    slice(str, s.a, (s.b - s.a) + 1)

proc `==`*(svs: StringVSlice, s: string): bool {.noSideEffect.} =
    if svs.len != s.len:
        return false
    for i in 0..svs.len-1:
        if svs[i] != s[i]:
            return false
    return true

proc `==`*[T](vs1, vs2: VSlice[T]): bool {.noSideEffect.} =
    if vs1.len != vs2.len:
        return false
    for i in 0..vs1.len-1:
        if vs1[i] != vs2[i]:
            return false
    return true

proc `==`*[T](vs: VSlice[T], arr: openArray[T]): bool {.noSideEffect.} =
    if vs.len != arr.len:
        return false
    for i in 0..vs.len-1:
        if vs[i] != arr[i]:
            return false
    return true

proc write*[T](stream: File | Stream, vs: VSlice[T]) =
    ## write a vslice to a file/stream without additional allocations (avoid string allocation)
    stream.write("&[")
    for i in 0..vs.len-1:
        stream.write(vs.data[i])
        if i < vs.len-1:
            stream.write(", ")
    stream.write(']')

proc write*(stream: File | Stream, svs: StringVSlice) =
    ## write a string vslice to a file/stream without additional allocations
    for c in svs:
        stream.write(c)
