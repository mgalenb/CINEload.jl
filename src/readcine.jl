#=
original code by stillyslalom on github
modified by mgalenb
CINE file version 13.0.770.0 (September 2017)
=#

mutable struct Time64
    Fractions::UInt32 		#=
                            Fractions of seconds (resolution 1/4Gig i.e. approx. 1/4 ns)
					        The fractions of second are stored here multiplied by 2^32
					        2 least significant bits pertain to IRIG triggering info, and must
				            be discarded (NOT in documentation; rather, in phcon.h)
                            =#
    Seconds::UInt32   		#=
                            Seconds. Seconds starting form Jan 1, 1970 (may year: 2038 signed, 2106 unsigned). All absolute time stored in a cine file is UTC.
                            =#
end

function parseTime64(phtime64)
	UTCOffset = Dates.value(Second(Hour(now())-Hour(now(tz"UTC"))))
	curTim = phtime64.Seconds + UTCOffset

	return phtime64.Seconds  + UTCOffset  + (phtime64.Fractions/4)/2^30
end

mutable struct winRECT
	left::Int32
	top::Int32
	right::Int32
	bottom::Int32
end

mutable struct WBGAIN
	R::Float32
	B::Float32
end

mutable struct tagIMFILTER
	dim::Int32
	shifts::Int32
	bias::Int32
	Coef::Int32
end

function cineheader(fname)
    h = OrderedDict()

    open(fname) do f
        # Check magic number
        read(f, UInt16) == UInt(18755) || error(basename(fname), " is not a .cine file")

        fhtypes = OrderedDict(          # File header
            :HeadSize       => UInt16,
            :Compression    => UInt16,
            :Version        => UInt16,
            :FirstImageIndex => Int32,
            :TotalImages    => UInt32,
            :FirstImageNum  => Int32,
            :ImCount        => UInt32,
            :OffImageHeader => UInt32,
            :OffSetup       => UInt32,
            :OffImageOffset => UInt32,
            :TriggerFrac    => UInt32,
            :TriggerSec     => UInt32
        )
        ihtypes = OrderedDict(          # Image header
            :ImHeadSize     => UInt32,
            :Width          => Int32,
            :Height         => Int32,
            :Planes         => UInt16,
            :BitDepth       => UInt16,
            :Comp           => UInt32,
            :SizeImage      => UInt32,
            :PxPerMX        => UInt32,
            :PxPerMY        => UInt32,
            :ClrUsed        => UInt32,
            :ClrImportant   => UInt32
        )

        shtypes = OrderedDict(          # setup header
            :FrameRate      => UInt16,
            :Shutter        => UInt16,
            :PostTrigger    => UInt16,
            :FrameDelay     => UInt16,
            :AspectRatio    => UInt16,
            :Res7           => UInt16,
            :Res8           => UInt16,
            :Res9           => UInt8,
            :Res10          => UInt8,
            :Res11          => UInt8,
            :TrigFrame      => UInt8,
            :Res12          => UInt8,
            :DescriptionOLD => String,
            :Mark           => UInt16,
            :SetupLength    => UInt16,
            :Res13          => UInt16,
			:SigOptions		=> UInt16,
			:BinChannels	=> Int16,
			:SamplesPerImage	=> UInt8,
			:BinName		=> String, #THINGS COULD GET OUT OF ORDER FROM HERE ON...
			:AnaOption		=> UInt16,
			:AnaChannels	=> UInt16,
			:Res6			=> UInt8,
			:AnaBoard		=> UInt8,
			:ChOption		=> Int16,
			:AnaGain		=> Float32,
			:AnaUnit		=> String,
			:AnaName		=> String,
			:lFirstImage	=> Int32,
			:dwImageCount	=> UInt32,
			:nQFactor		=> Int16,
			:wCineFileType	=> UInt16,
			:szCinePath		=> String,
			:Res14			=> UInt16,
			:Res15			=> UInt8,
			:Res16			=> UInt8,
			:Res17			=> UInt16,
			:Res18			=> Float64,
			:Res19			=> Float64,
			:Res20			=> UInt16,
			:Res1			=> Int32,
			:Res2			=> Int32,
			:Res3			=> Int32,
			:ImWidth		=> UInt16,
			:ImHeight		=> UInt16,
			:EDRShutter16	=> UInt16,
			:Serial			=> UInt32,
			:Saturation		=> Int32,
			:Res5			=> UInt8,
			:AutoExposure	=> UInt32,
			:bFlipH			=> Bool,
			:bFlipV			=> Bool,
			:Grid			=> UInt32,
			:FrameRate		=> UInt32,
			:Shutter		=> UInt32,
			:EDRShutter		=> UInt32,
			:PostTrigger	=> UInt32,
			:FrameDelay		=> UInt32,
			:bEnableColor	=> Bool,
			:CameraVersion	=> UInt32,
			:FrimwareVersion	=> UInt32,
			:SoftwareVersion	=> UInt32,
			:RecordingTimeZone	=> Int32,
			:CFA			=> UInt32,
			:Bright			=> Int32,
			:Contrast		=> Int32,
			:Gamma			=> Int32,
			:Res21			=> UInt32,
			:AutoExpLevel	=> UInt32,
			:AutoExpSpeed	=> UInt32,
			#:AutoExpRect		=> winRECT(1,1,1,1)
			:AutoExpRectLeft	=> Int32,
			:AutoExpRectTop		=> Int32,
			:AutoExpRectRight	=> Int32,
			:AutoExpRectBottom	=> Int32,
			:WBGain11		=> Float32,
			:WBGain12		=> Float32,
			:WBGain21		=> Float32,
			:WBGain22		=> Float32,
			:WBGain31		=> Float32,
			:WBGain32		=> Float32,
			:WBGain41		=> Float32,
			:WBGain42		=> Float32,
			:Rotate			=> Int32,
			:WBView1		=> Float32,
			:WBView2		=> Float32,
			:RealBPP		=> UInt32,
			:Conv8min		=> UInt32,
			:Conv8max		=> UInt32,
			:FilterCode		=> Int32,
			:FilterParam	=> Int32,
			:UF				=> String,
			:BlackCalSVer	=> UInt32,
			:WhiteCalSVer	=> UInt32,
			:GrayCalSVer	=> UInt32,
			:bStampTime		=> Bool,
			:SoundDest		=> UInt32,
			:FRPSteps		=> UInt32,
			:FRPImgNr		=> Array,
			:FRPRate		=> Array,
			:FRPExp			=> Array,
			:MCCnt			=> Int32,
			:MCPercent		=> Array,
			:CICalib		=> UInt32,
			:CalibWidth		=> UInt32,
			:CalibHeight	=> UInt32,
			:CalibRate		=> UInt32,
			:CalibExp		=> UInt32,
			:CalibEDR		=> UInt32,
			:CalibTemp		=> UInt32,
			:HeadSerial		=> Array,
			:RangeCode		=> UInt32,
			:RangeSize		=> UInt32,
			:Decimation		=> UInt32,
			:MasterSerial	=> UInt32,
			:Sensor			=> UInt32,
			:ShutterNs		=> UInt32,
			:EDRShutterNs	=> UInt32,
			:FrameDelayNs	=> UInt32,
			:ImPosXAcq		=> UInt32,
			:ImPosYAcq		=> UInt32,
			:ImWidthAcq		=> UInt32,
			:ImHeightAcq	=> UInt32,
			:Description	=> String,
			:RisingEdge		=> Bool
        )

        tbhtypes = OrderedDict(         # tagged block header
            :TagBlkSize     => UInt32,
            :TagBlkType     => UInt16,
            :TagBlkRes      => UInt16,
        )

        for (ID, headertype) in fhtypes     # Read .cine file header
            h[ID] = read(f, headertype)
        end

        seek(f, h[:OffImageHeader])
        for (ID, headertype) in ihtypes     # Read image header
            h[ID] = read(f, headertype)
        end

        seek(f, h[:OffSetup])
        for (ID, headertype) in shtypes     # read setup header
            if cmp(String(ID),"DescriptionOLD") == 0
                h[ID] = String(read(f,121))
			elseif cmp(String(ID),"BinName") == 0
				h[ID] = String(read(f,8*11))
			elseif cmp(String(ID),"AnaUnit") == 0
				h[ID] = String(read(f,8*6))
			elseif cmp(String(ID),"AnaName") == 0
				h[ID] = String(read(f,8*11))
			elseif cmp(String(ID),"szCinePath") == 0
				h[ID] = String(read(f,4*65))
			elseif cmp(String(ID),"UF") == 0 #skip reading image filter for now
				skip(f,4*(3+5*5))
			elseif cmp(String(ID),"FRPImgNr") == 0
				h[ID] = [read(f,Int32) for i in 1:16]
			elseif cmp(String(ID),"FRPRate") == 0
				h[ID] = [read(f,UInt32) for i in 1:16]
			elseif cmp(String(ID),"FRPExp") == 0
				h[ID] = [read(f,UInt32) for i in 1:16]
			elseif cmp(String(ID),"MCPercent") == 0
				h[ID] = [read(f,Float32) for i in 1:64]
			elseif cmp(String(ID),"HeadSerial") == 0
				h[ID] = [read(f,UInt32) for i in 1:4]
			elseif cmp(String(ID),"Description") == 0
				h[ID] = String(read(f,4096))
            else
                h[ID] = read(f, headertype)
            end
        end

#= I havent been able to get this method of reading tagged info blocks to work...
        if (h[:OffSetup] + h[:SetupLength]) < h[:OffImageOffset]
            seek(f,h[:OffSetup] + h[:SetupLength])

            for (ID, headertype) in tbhtypes     # Read tagged information block header
                h[ID] = read(f, headertype)
            end
            if h[:TagBlkType] == 1002
                h[:TimeOnlyData] = [read(f,h[:TagBlkSize]-8)]
            else
                skip(f,h[:TagBlkSize]-8)
            end
        end
=#
        h[:BitType] = h[:BitDepth] == 8 ? N0f8 : N4f12 #Gray{N0f8} : Gray{N4f12}
		#Phantom CINE frames loaded as FixedPointNumbers and not as Gray{} type. Gray{} type is interpreted in Juno and IJulia to indicate an Array is an image and should be plotted as an such, if `Images` is loaded. Use Gray.(img) to convert FixedPointNumbers to Gray{FixedPointNumbers}, which will be shown as an image.

        numframes = h[:ImCount]
        numframes > 0 || error("no images exist in file")

        seek(f, h[:OffImageOffset])
        h[:ImLocs] = read!(f, Array{Int64}(undef, numframes))

		#Here we do a hack to read some of the Tagged information blocks
        seekstart(f)
        i = 1
        while read(f, UInt16) != 1002   # Read up to Time Only Block in Tagged Information Blocks
            i += 1
        end
        h[:TimeOnlyBLockOffset] = i

        dt = zeros(numframes)
        skip(f, 2) # skips the UInt16 that is "Reserved" in tagged info blocks structure
        for i = 1:numframes     # Calculate dt for each frame
            fracstart = (read(f, UInt32)/4)/2^30 # read first UInt32 of Time64 struct (not implimented)
            secstart  = read(f, UInt32) # read second UInt32 of Time64 struct (not implimented)
            dt[i] = (secstart - h[:TriggerSec]) + ((fracstart - h[:TriggerFrac]/4/2^30))
        end
        h[:DeltaT] = dt

		while read(f,UInt16) != 1003 # Read up to Exposure only block
			i += 1
		end
		h[:ExposureOnlyBlockOffset] = i

		exposure = zeros(numframes)
		skip(f, 2) # skips the UInt16 that is "Reserved" in tagged info blocks structure
		for i = 1:numframes
			curExposure = (read(f,UInt32)/2^32) #current frame exposure time in seconds
			exposure[i] = curExposure
		end
		h[:frameExposure] = exposure
    end

    h[:Tmp] = Array{h[:BitType]}(undef, h[:Width], h[:Height])

    return h
end

function readframe!(f::IO, frame, h, frameidx)
    frameidx <= h[:ImCount] || error("tried to access nonexistent frame $frameidx")
    seek(f, h[:ImLocs][frameidx])
    skip(f, read(f, UInt32) - 4)
    read!(f, h[:Tmp])
    frame .= rotl90(h[:Tmp])
end

readframe!(fname, frame, h, frameidx) = open(f -> readframe!(f, frame, h, frameidx), fname)
readframe(f, h, frameidx) = readframe!(f, rotl90(h[:Tmp]), h, frameidx)

function readframe(f, h, frameidxs::AbstractVector{Int})
    img = similar(h[:Tmp], h[:Height], h[:Width], length(frameidxs))
    for (i, frameidx) in enumerate(frameidxs)
        frame = @view img[:,:,i]
        readframe!(f, frame, h, fidx)
    end
    return img
end

function readcine(fname)
    h = cineheader(fname)
    img = Array{h[:BitType]}(undef, h[:Height], h[:Width], h[:ImCount])
    open(fname) do f
        @showprogress .1 "Loading $(basename(fname)) " for i = 1:h[:ImCount]
            frame = @view img[:,:,i]
            readframe!(f, frame, h, i)
        end
    end
    return img, h
end

readcine(fname, h) = readcine(fname)[1]
