//
//  BufferTypes.swift
//  AccessibleVideo
//
//  Created by Luke Groeninger on 12/27/14.
//  Copyright (c) 2014 Luke Groeninger. All rights reserved.
//



class MetalBuffer {
    var buffer:MTLBuffer? = nil
    internal var _filterBufferData:UnsafePointer<Void> = nil
    internal var _filterBufferSize:Int = 0
    
    init!(arguments:MTLArgument) {
        let size = arguments.bufferDataSize
        let dev = MTLCreateSystemDefaultDevice()
        
        if let b = dev.newBufferWithLength(size, options: nil) {
            buffer = b
            _filterBufferData = UnsafePointer<Void>(b.contents())
            _filterBufferSize = size
            setContents(arguments)
        } else {
            return nil
        }
    }
    
    required init!(base:UnsafePointer<Void>, size:Int) {
        if base != nil {
            _filterBufferData = base
            _filterBufferSize = size
        } else {
            return nil
        }
    }
    
    func setContents(arguments: MTLArgument) {
        assert(false, "This should not be getting called!")
    }
}

class MetalBufferArray<T:MetalBuffer> {
    var buffer:MTLBuffer? = nil
    internal var _filterBufferData:UnsafePointer<Void> = nil
    internal var _filterBufferSize:Int = 0
    lazy internal var _members = [T]()
    internal var _count:Int = 0
    
    init!(arguments:MTLArgument, count:Int){
        let size = arguments.bufferDataSize
        let dev = MTLCreateSystemDefaultDevice()
        
        if let b = dev.newBufferWithLength(size * count, options: nil) {
            buffer = b
            _filterBufferData = UnsafePointer<Void>(b.contents())
            _filterBufferSize = size
            _count=count
            for i in 0..<count {
                if let element = (T.self as T.Type)(base: _filterBufferData + size * i, size: size) {
                    element.setContents(arguments)
                    _members.append(element)
                }
            }
        } else {
            return nil
        }
    }
    
    subscript (element:Int) -> T {
        get {
            assert(element >= 0 && element < _count, "Index out of range")
            return _members[element]
        }
    }

    func bufferAndOffsetForElement(element:Int) -> (MTLBuffer, Int){
        assert(element >= 0 && element < _count, "Index out of range")
        return (buffer!,_filterBufferSize * element)
    }
    
    func offsetForElement(element:Int) -> Int {
        assert(element >= 0 && element < _count, "Index out of range")
        return _filterBufferSize * element
    }
    
    var count:Int {
        return _count
    }
}

// type takes in a UIColor or CGFloats and writes them out as an
// 8-bit per channel RGBA vector
struct Color {
    private var _base:UnsafeMutablePointer<UInt8> = nil
    init(buffer:UnsafeMutablePointer<UInt8>) {
        _base = buffer
    }
    
    var color:UIColor {
        get {
            return UIColor(red: r, green: g, blue: b, alpha: a)
        }
        set {
            newValue.getRed(&r, green: &g, blue: &b, alpha: &a)
        }
    }
    
    var r:CGFloat {
        get {
            return CGFloat(Float(_base[0]) / 255.0)
        }
        set {
            _base[0] = UInt8(newValue * 255.0)
        }
    }
    var g:CGFloat {
        get {
            return CGFloat(Float(_base[1]) / 255.0)
        }
        set {
            _base[1] = UInt8(newValue * 255.0)
        }
    }
    var b:CGFloat {
        get {
            return CGFloat(Float(_base[2]) / 255.0)
        }
        set {
            _base[2] = UInt8(newValue * 255.0)
        }
    }
    var a:CGFloat {
        get {
            return CGFloat(Float(_base[3]) / 255.0)
        }
        set {
            _base[3] = UInt8(newValue * 255.0)
        }
    }
}


// type takes in a row-major matrix and writes it so that
// it is a column-major matrix where each column is aligned on
// 4 byte boundaries
struct Matrix3x3 {
    private var _base:UnsafeMutablePointer<Float32> = nil
    init(buffer:UnsafeMutablePointer<Float32>) {
        _base = buffer
    }
    
    private func indexIsValidForRow(row: Int, column: Int) -> Bool {
        return row >= 0 && row < 3 && column >= 0 && column < 3
    }
    
    subscript(row:Int, column:Int) -> Float32 {
        get {
            assert(indexIsValidForRow(row, column: column), "Index out of range")
            // convert to column-major order
            return _base[(column * 4) + row]
        }
        set {
            assert(indexIsValidForRow(row, column: column), "Index out of range")
            // convert to column-major order
            _base[(column * 4) + row] = newValue
        }
    }
    
    subscript(row:Int) -> (Float32, Float32, Float32) {
        get {
            assert(row >= 0 && row < 3, "Index out of range")
            // convert to column-major order
            return (_base[row], _base[row + 4], _base[row + 8])
        }
        set {
            assert(row >= 0 && row < 3 , "Index out of range")
            // convert to column-major order
            _base[row] = newValue.0
            _base[row + 4] = newValue.1
            _base[row + 8] = newValue.2
        }
    }
    
    func set(matrix:((Float32, Float32, Float32), (Float32, Float32, Float32), (Float32, Float32, Float32))) {
        // converts to column-major order
        // aligns each column to 4-byte boundaries
        _base[0] = matrix.0.0
        _base[4] = matrix.0.1
        _base[8] = matrix.0.2
        _base[1] = matrix.1.0
        _base[5] = matrix.1.1
        _base[9] = matrix.1.2
        _base[2] = matrix.2.0
        _base[6] = matrix.2.1
        _base[10] = matrix.2.2
    }
    
    func clear() {
        for column in 0...2 {
            for row in 0...2 {
                _base[(column * 4) + row] = 0.0
            }
        }
    }
    
    func clearIdentity() {
        for column in 0...2 {
            for row in 0...2 {
                _base[(column * 4) + row] = (column == row) ? 1.0 : 0.0
            }
        }
    }
}