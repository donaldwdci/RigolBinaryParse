module RigolBinaryParse

export getWaveform, getWaveformDataFrame, getWaveformProperties, getUnits, downsample, plotWave, cropWave

using DataFrames
using Plots

struct FileHeader

    cookie::String
    version::String
    filesize::Int32
    waveform_count::Int32

end

struct WaveformHeader

    header_size::Int32
    waveform_type::Int32
    waveform_buffer_count::Int32
    point_count::Int32
    count::Int32
    x_display_range::Float32
    x_display_origin::Float64
    x_increment::Float64
    x_origin::Float64
    x_units::Int32
    y_units::Int32
    date::String
    time::String
    model::String
    channel_name::String

end

struct WaveformDataHeader

    header_size::Int32
    buffer_type::Int16
    bytes_per_point::Int16
    buffer_size::Int64

end


struct WaveformData

    x::Vector
    y::Vector
    header::WaveformHeader
    dataHeader::WaveformDataHeader

end


struct Waveform

    header::FileHeader
    waveform::Vector{WaveformData}

end



# Getting Units
function getUnits(units::Int32)::String

    if units == 0
        return "Unkown"
    elseif units == 1
        return "Volts (V)"
    elseif units == 2
        return "Seconds (s)"
    elseif units == 3
        return "Constant"
    elseif units == 4
        return "Amps (A)"
    elseif units == 5
        return "Decibel (dB)"
    elseif units == 6
        return "Hertz (Hz)"
    else
        return "Unkown"
    end

end

function getUnits(waveform::WaveformData)::Tuple{String,String}

    return (getUnits(waveform.header.x_units), getUnits(waveform.header.y_units))

end

function getUnits(waveform::Waveform)::Vector

    vector_length = length(waveform.waveform)
    units = Vector{Tuple{String,String}}(undef, vector_length)

    for i in eachindex(waveform.waveform)
        units[i] = getUnits(waveform.waveform[i])
    end

    return units

end



function getWaveformType(waveformType::Int32)::String

    if waveformType == 0
        return "Unkown"
    elseif waveformType == 1
        return "Normal"
    elseif waveformType == 2
        return "Peak Detection"
    elseif waveformType == 3
        return "Average"
    elseif waveformType == 4
        return "Not Used"
    elseif waveformType == 5
        return "Note Used"
    elseif waveformType == 6
        return "Logic"
    else
        return "Unkown"
    end

end

function getBufferType(bufferType::Int16)::String

    if bufferType == 0
        return "Unkown"
    elseif bufferType == 1
        return "Normal 32-bit float data"
    elseif bufferType == 2
        return "Maximum float data"
    elseif bufferType == 3
        return "Minimum float data"
    elseif bufferType == 4
        return "Not Used"
    elseif bufferType == 5
        return "Digital unsigned 8-bit character data"
    else
        return "Unkown"
    end

end




function getInt16(vector::Vector)::Int16
    return first(reinterpret(Int16, vector))
end

function getInt32(vector::Vector)::Int32
    return first(reinterpret(Int32, vector))
end

function getInt64(vector::Vector)::Int64
    return first(reinterpret(Int64, vector))
end

function getFloat32(vector::Vector)::Float32
    return first(reinterpret(Float32, vector))
end

function getFloat64(vector::Vector)::Float64
    return first(reinterpret(Float64, vector))
end

function getString(vector::Vector{UInt8})::String

    newVector::Vector{UInt8} = []

    for i in 1:length(vector)
        if vector[i] != 0
            push!(newVector, vector[i])
        else
            break
        end
    end

    return String(newVector)

end



function getFileHeader(binData::Vector)::FileHeader

    return FileHeader(
        getString(binData[1:2]),# Cookie
        getString(binData[3:4]),# Version
        getInt32(binData[5:8]), # File Size
        getInt32(binData[9:12]) # Waveform Count
    )

end



function getWaveformHeader(binData::Vector)::WaveformHeader

    return WaveformHeader(
        getInt32(binData[1:4]),             # Header Size
        getInt32(binData[5:8]),             # Waveform Type
        getInt32(binData[9:12]),            # Number of Waveform Buffers
        getInt32(binData[13:16]),           # Number of Points
        getInt32(binData[17:20]),           # Count
        getFloat32(binData[21:24]),         # X Display Range
        getFloat64(binData[25:32]),         # X Display Origin
        getFloat64(binData[33:40]),         # X Increment
        getFloat64(binData[41:48]),         # X Origin
        getInt32(binData[49:52]),           # X Units
        getInt32(binData[53:56]),           # Y Units
        getString(binData[57:72]),          # Date
        getString(binData[73:88]),          # Time
        getString(binData[89:112]),         # Model
        getString(binData[113:128])         # Channel Name
    )

end



function getWaveformDataHeader(binData::Vector)::WaveformDataHeader

    return WaveformDataHeader(
        getInt32(binData[1:4]), # Header Size
        getInt16(binData[5:6]), # Buffer Type
        getInt16(binData[7:8]), # Bytes Per Point
        getInt32(binData[9:12]) # Buffer Size
    )

end



function getWaveformDataPoints(binData::Vector, dataHeader::WaveformDataHeader)::Vector

    if dataHeader.buffer_type <= 4

        if dataHeader.bytes_per_point == 2
            return reinterpret(Float16, binData[1:dataHeader.buffer_size])
        elseif dataHeader.bytes_per_point == 4
            return reinterpret(Float32, binData[1:dataHeader.buffer_size])
        elseif dataHeader.bytes_per_point == 8
            return reinterpret(Float64, binData[1:dataHeader.buffer_size])
        end

    else
        return binData[1:dataHeader.buffer_size]
    end

end



function getWaveformData(binData::Vector)::WaveformData

    waveformHeader = getWaveformHeader(binData[1:140])
    waveformDataHeader = getWaveformDataHeader(binData[141:152])

    y_data_points = getWaveformDataPoints(binData[153:(152+waveformDataHeader.buffer_size)], waveformDataHeader)

    x_data_points = (0-waveformHeader.x_display_origin):waveformHeader.x_increment:((waveformHeader.x_increment*(waveformHeader.point_count-1))-waveformHeader.x_display_origin)


    return WaveformData(x_data_points, y_data_points, waveformHeader, waveformDataHeader)

end



function getWaveform(binData::Vector)::Waveform

    fileHeader = getFileHeader(binData)

    waveformData::Vector{WaveformData} = []

    if fileHeader.waveform_count > 0

        binaryStartIndex::Int64 = 13

        for i in 1:fileHeader.waveform_count
            push!(waveformData, getWaveformData(binData[binaryStartIndex:length(binData)]))
            binaryStartIndex += 140 + 12 + waveformData[i].dataHeader.buffer_size
        end

    end

    return Waveform(fileHeader, waveformData)

end

function getWaveform(fileLocation::String)::Waveform
    return getWaveform(read(fileLocation))
end




function getWaveformProperties(waveform::Waveform)::DataFrame

    df = DataFrame(
        "Header Size" => Int32[],
        "Waveform Type" => String[],
        "Number of Waveform Buffers" => Int32[],
        "Number of Points" => Int32[],
        "Count" => Int32[],
        "X Display Range" => Float32[],
        "X Display Origin" => Float64[],
        "X Increment" => Float64[],
        "X Origin" => Float64[],
        "X Units" => String[],
        "Y Units" => String[],
        "Date" => String[],
        "Time" => String[],
        "Model" => String[],
        "Channel Name" => String[],
        "Data Header Size" => Int32[],
        "Buffer Type" => String[],
        "Bytes Per Point" => Int16[],
        "Buffer Size" => Int64[]
    )

    for i in 1:waveform.header.waveform_count
        push!(df,
            [
                waveform.waveform[i].header.header_size,
                getWaveformType(waveform.waveform[i].header.waveform_type),
                waveform.waveform[i].header.waveform_buffer_count,
                waveform.waveform[i].header.point_count,
                waveform.waveform[i].header.count,
                waveform.waveform[i].header.x_display_range,
                waveform.waveform[i].header.x_display_origin,
                waveform.waveform[i].header.x_increment,
                waveform.waveform[i].header.x_origin,
                getUnits(waveform.waveform[i].header.x_units),
                getUnits(waveform.waveform[i].header.y_units),
                waveform.waveform[i].header.date,
                waveform.waveform[i].header.time,
                waveform.waveform[i].header.model,
                waveform.waveform[i].header.channel_name,
                waveform.waveform[i].dataHeader.header_size,
                getBufferType(waveform.waveform[i].dataHeader.buffer_type),
                waveform.waveform[i].dataHeader.bytes_per_point,
                waveform.waveform[i].dataHeader.buffer_size
            ]
        )
    end

    return df

end

function getWaveformDataFrame(waveform::Waveform)::DataFrame

    #t = 0:waveform.waveform[1].header.x_increment:(waveform.waveform[1].header.x_increment*(waveform.waveform[1].header.point_count-1))

    df = DataFrame(time=waveform.waveform[1].x, ch1=waveform.waveform[1].y)

    if waveform.header.waveform_count > 1
        for i in 2:waveform.header.waveform_count
            colname = "ch$i"
            df[!, colname] = waveform.waveform[i].y
        end
    end

    return df

end


# Selecting a time range of data

function cropWave(wave::WaveformData, start_time, end_time)

    start_index::Int = ceil(start_time/wave.header.x_increment + wave.header.x_origin/wave.header.x_increment)
    end_index::Int = ceil(end_time/wave.header.x_increment + wave.header.x_origin/wave.header.x_increment)

    return (wave.x[start_index:end_index], wave.y[start_index:end_index])

end


# Down Sampling Data

function downsample(data::Vector, max_length::Int=5000)::Vector

    increment::Int = ceil(length(data)/max_length)

    return data[1:increment:length(data)]

end

function downsample(waveform::WaveformData, max_length::Int=5000)::Tuple{Vector,Vector}

    return (downsample(waveform.x, max_length), downsample(waveform.y, max_length))

end

function downsample(waveform::Waveform, max_length::Int=5000)::Vector

    result::Vector{Tuple{Vector,Vector}} = []

    for i in eachindex(waveform.waveform)
        push!(result, downsample(waveform.waveform[i], max_length))
    end

    return result

end



# Basic Quick Plots

function plotWave(wave::WaveformData)::Plots.Plot

    (x, y) = downsample(wave)
    (x_units, y_units) = getUnits(wave)

    maxVal = maximum(y)
    minVal = minimum(y)
    rng = abs(maxVal-minVal)
    ylims = (minVal-(rng/2.0), maxVal+(rng/2.0))

    return Plots.plot(x, y, title=wave.header.channel_name, xlabel=x_units, ylabel=y_units, ylims=ylims)

end

function plotWave(wave::Waveform)::Plots.Plot

    plt::Vector{Plots.Plot}=[]

    for i in eachindex(wave.waveform)

        push!(plt, plotWave(wave.waveform[i]))

    end

    return Plots.plot(plt...)

end

end
