using RigolBinaryParse
using Test

#@testset "RigolBinaryParse.jl" begin

# locate bin file recorded from RIGOL oscilloscope
bin_file = "C:\\TEMP\\RIGOL_BIN_FILE.bin"

# get struct format for wave data and properties
wave_struct = getWaveform(bin_file)

# get datagrame format for data
wave_dataframe = getWaveformDataFrame(wave_struct)

# get dataframe format for properties
wave_properties = getWaveformProperties(wave_struct)

#end
