# RigolBinaryParse

[![Build Status](https://github.com/donaldwdci/RigolBinaryParse.jl/actions/workflows/CI.yml/badge.svg?branch=)](https://github.com/donaldwdci/RigolBinaryParse.jl/actions/workflows/CI.yml?query=branch%3A)

Below is the documentation for using the RIGOL binary parse for Julia.
# Data
## Private
```julia unfold:"fileHeader"
struct FileHeader

	cookie::String
	version::String
	filesize::Int32
	waveform_count::Int32

end
```
```julia unfold:"WaveformHeader"
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
```
```julia fold:"WaveformataHeader"
struct WaveformDataHeader

    header_size::Int32
    buffer_type::Int16
    bytes_per_point::Int16
    buffer_size::Int64
    
end
```
```julia fold:"WaveformData"
struct WaveformData

    data::Vector
    header::WaveformHeader
    dataHeader::WaveformDataHeader
    
end
```
```julia fold:"Waveform"
struct Waveform

    header::FileHeader
    waveform::Vector{WaveformData}
    
end
```
## Public
N/A
# Functions
## Private
`{julia}function getUnits(Int32)::String`
`{julia}function getWaveformType(Int32)::String`
`{julia}function getBufferType(Int16)::String`
`{julia}function getFileHeader(Vector)::FileHeader`
`{julia}function getWaveformHeader(Vector)::WaveformHeader`
`{julia}function getWaveformDataHeader(Vector)::WaveformDataHeader`
`{julia}function getWaveformDataPoints(Vector, WaveformDataHeader)::Vector`
`{julia}function getWaveformData(Vector)::WaveformData`
## Public
`{julia}function getWaveform(Vector)::Waveform`
`{julia}function getWaveform(String)::Waveform`
`{julia}function getWaveformProperties(Waveform)::DataFrame`
`{julia}function getWaveformDataFrame(Waveform)::DataFrame`
# Waveform Data Structure
```text
header
    cookie
	version
	filesize
	waveform_count
waveform[]
	data
	header
		header_size
		waveform_type
		waveform_buffer_count
		point_count
		count
		x_display_range
		x_display_origin
		x_increment
		x_origin
		x_units
		y_units
		date
		time
		model
		channel_name
	dataHeader
		header_size
		buffer_type
		bytes_per_point
		buffer_size
```
# Examples
```julia
using .RIGOL

file1 = "C:\\Users\\DonaldW\\Documents\\binarydata.bin"

wave = getWaveform(file1)

data = getWaveformDataFrame(wave)

specs = RIGOL.getWaveformProperties(wave)
```