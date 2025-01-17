	SUBROUTINE SNDMIX ( nlun, lun, mxdpth, nparms, nlevel,
     +			    hdata, tlclk, plcl, thtwlcl, hlcl, iret )
C************************************************************************
C* SNDMIX								*
C*									*
C* This routine will compute the temperature, dewpoint, pressure and	*
C* height of the LCL for the lowest layer of the sounding.		*
C*									*
C* SNDMIX ( NLUN, LUN, MXDPTH, NPARMS, NLEVEL, HDATA, TLCLK, PLCL,	*
C*	    THTWLCL, HLCL, IRET )					*
C*									*
C* Input parameters:							*
C*	NLUN		INTEGER		Number of file numbers		*
C*	LUN (NLUN)	INTEGER		File numbers			*
C*	MXDPTH		CHAR*		Depth of mix layer		*
C*	NPARMS		INTEGER		Number of parameters		*
C*	NLEVEL		INTEGER		Number of levels		*
C*	HDATA (LLMXLV)	REAL		Interpolated sounding data	*
C*									*
C* Output parameters:							*
C*	TLCLK		REAL		Temperature at LCL		*
C*	PLCL		REAL		Pressure at LCL			*
C*	THTWLCL		REAL		Wetbulb pot. temperature at LCL	*
C*	HLCL		REAL		Height of the LCL		*
C*	IRET		INTEGER		Return code			*
C*					  0 = normal			*
C**									*
C* Log:									*
C* S. Jacobs/SSAI	 4/92						*
C* J. Whistler/SSAI	 4/93		Cleaned up header		*
C* J. Whistler/SSAI	 6/93		set ANGFLG to false		*
C************************************************************************
	INCLUDE		'GEMPRM.PRM'
	INCLUDE		'sndiag.prm'
C*
	INTEGER		lun(*)
	CHARACTER*(*)	mxdpth
	REAL		hdata(*)
C*
	REAL		adata(4), bdata(4), outdat(4)
	LOGICAL		intflg(4), angflg(4), chkflg
C*
	INCLUDE		'ERMISS.FNC'
C------------------------------------------------------------------------
C*	Initialize the variables for the routine.
C
	iret = 0
	intflg(1) = .false.
	DO  j = 2, 4
	    intflg(j) = .true.
	END DO
	DO  j = 1, 4
	    angflg(j) = .false.
	END DO
	DO  j = 1, 4
	    outdat(j) = RMISSD
	END DO
C
C*	Get the depth value.
C
	CALL ST_CRNM ( mxdpth, depth, ier )
C
	IF  ( (ier .ne. 0) .or. (depth .le. 0.) )  THEN
C
C*	    If the depth is 0 or missing, then use the lowest
C*	    level values for the averages.
C
	    depth = 0.
	    presavg = hdata(0*nparms+IPRES)
	    tempavg = hdata(0*nparms+ITEMP)
	    dwptavg = hdata(0*nparms+IDWPT)
	    avgmixr = PR_MIXR ( dwptavg, presavg )
	    thtaavg = PR_THTA ( tempavg, presavg )
	ELSE
C
C*	    Otherwise, interpolate to the top of the mixed layer.
C
	    dht = hdata(0*nparms+IHGHT) + depth
	    sump = 0.
	    sumt = 0.
	    sumtd = 0.
	    i = 1
C
C*	    Find the top of the mixed layer.
C
	    DO  WHILE ( hdata((i-1)*nparms+IHGHT) .lt. dht )
		i = i + 1
	    END DO
C
	    IF  ( hdata((i-1)*nparms+IHGHT) .eq. dht )  THEN
C
C*		If the top of the mixed layer falls on an existing
C*		level, use the values for the level.
C
		pres = hdata((i-1)*nparms+IPRES)
		temp = hdata((i-1)*nparms+ITEMP)
		dwpt = hdata((i-1)*nparms+IDWPT)
		write(6,*)pres,temp,dwpt
	    ELSE
C
C*		Otherwise, interpolate to the level at the top of
C*		the layer.
C
		adata(1) = hdata((i-1-1)*nparms+IHGHT)
		bdata(1) = hdata((i-1  )*nparms+IHGHT)
		adata(2) = hdata((i-1-1)*nparms+IPRES)
		bdata(2) = hdata((i-1  )*nparms+IPRES)
		adata(3) = hdata((i-1-1)*nparms+ITEMP)
		bdata(3) = hdata((i-1  )*nparms+ITEMP)
		adata(4) = hdata((i-1-1)*nparms+IDWPT)
		bdata(4) = hdata((i-1  )*nparms+IDWPT)
		CALL PC_INTH ( dht, adata, bdata, 4, intflg, angflg, 1,
     +			   outdat, ier )
		pres = outdat(2)
		temp = outdat(3)
		dwpt = outdat(4)
		write(6,*)'flag 1', adata(4),bdata(4),dwpt
	    END IF
C
C*	    Sum the parameter values through the mixed layer.
C
	    itop = i
	    DO  j = 2, itop-1
		dz   = hdata((j-1)*nparms+IHGHT) -
     +			hdata((j-1-1)*nparms+IHGHT)
		sump = sump + ( .5 * dz * ( hdata((j-1)*nparms+IPRES) +
     +			hdata((j-1-1)*nparms+IPRES) ) )
		sumt = sumt + ( .5 * dz * ( hdata((j-1)*nparms+ITEMP) +
     +			hdata((j-1-1)*nparms+ITEMP) ) )
		sumtd = sumtd+( .5 * dz * ( hdata((j-1)*nparms+IDWPT) +
     +			hdata((j-1-1)*nparms+IDWPT) ) )
	    END DO
	    dz   = dht -  hdata((itop-1-1)*nparms+IHGHT)
	    sump = sump + ( .5 * dz *
     +			( hdata((itop-1-1)*nparms+IPRES) + pres ) )
	    sumt = sumt + ( .5 * dz *
     +			( hdata((itop-1-1)*nparms+ITEMP) + temp ) )
	    sumtd = sumtd + ( .5 * dz *
     +			( hdata((itop-1-1)*nparms+IDWPT) + dwpt ) )
C
C*	    Find the average values for the layer.
C
	    presavg = sump / depth
	    tempavg = sumt / depth
	    dwptavg = sumtd / depth
	    avgmixr = PR_MIXR ( dwptavg, presavg )
	    thtaavg = PR_THTA ( tempavg, presavg )
	END IF
C
C*	Compute the values at the LCL. (Temperature, Pressure,
C*					Wet-bulb Potential Temperature)
C
	IF  ( .not. ERMISS(tempavg) .and.
     +	      .not. ERMISS(presavg) .and.
     +	      .not. ERMISS(dwptavg) )  THEN
	    chkflg  = .true.
	    tlclk   = PR_TLCL ( tempavg, dwptavg )
	    tlclc   = PR_TMKC ( tlclk )
	    plcl    = PR_PLCL ( tempavg, presavg, tlclk )
	    thtwlcl = SND_THW ( tempavg, presavg, dwptavg )
C
C*	    Find the height of the LCL. Interpolate the data if
C*	    necessary.
C
	    i = 1
	    DO  WHILE ( hdata((i-1)*nparms+IPRES) .gt. plcl )
		i = i + 1
	    END DO
C
	    IF  ( hdata((i-1)*nparms+IPRES) .eq. plcl )  THEN
		hlcl  = hdata((i-1)*nparms+IHGHT)
	    ELSE
		rmult = ALOG ( plcl / hdata((i-1-1)*nparms+IPRES) ) /
     +			ALOG ( hdata((i-1)*nparms+IPRES) /
     +			       hdata((i-1-1)*nparms+IPRES) )
		hlcl  = hdata((i-1-1)*nparms+IHGHT) +
     +			( hdata((i-1)*nparms+IHGHT) - 
     +			  hdata((i-1-1)*nparms+IHGHT) ) * rmult
	    END IF
	ELSE
	    chkflg  = .false.
	    tlclk   = RMISSD
	    plcl    = RMISSD
	    thtwlcl = RMISSD
	    hlcl    = RMISSD
	END IF
C
C*	Write the output to all units.
C
	DO  k = 1, nlun
	    WRITE ( lun(k), 1000 )  depth, thtaavg, avgmixr
	    WRITE ( lun(k), 1001 )  pres, temp, dwpt
	    IF  ( chkflg )  THEN
		WRITE ( lun(k), 2000 ) hlcl, plcl, tlclc, thtwlcl
	    ELSE
		WRITE ( lun(k), 2001 )
	    END IF
	END DO
1000	FORMAT ( /, '      MIXED LAYER AVERAGE VALUES', /,/,
     +              ' Depth                 : ', F10.2, ' m', /, /,
     +              ' Potential Temperature : ', F10.2, ' K', /,
     +              ' Mixing Ratio          : ', F10.2, ' g/kg' )
1001	FORMAT ( /, '      TOP OF MIXED LAYER VALUES', /,/,
     +              ' Pressure              : ', F10.2, ' mb', /,
     +              ' Temperature           : ', F10.2, ' C', /,
     +              ' Dewpoint              : ', F10.2, ' C' )
2000	FORMAT ( /, '      LCL FOR THE MIXED LAYER', /,/,
     +              ' Height                         : ',F10.2,' m',/,
     +              ' Pressure                       : ',F10.2,' mb',/,
     +              ' Temperature                    : ',F10.2,' C',/,
     +              ' Wet-bulb Potential Temperature : ',F10.2,' C' )
2001	FORMAT ( /, ' LCL is too low, Temperature and Dewpoint ',
     +              'are missing at the surface. ', / )
C*
	RETURN
	END
