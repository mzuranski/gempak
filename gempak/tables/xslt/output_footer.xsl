<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
        <xsl:output method="xml"/>
    
    
    <!-- 
            OutputFooter
    
        This template produces the two footer lines for an an AIRMET bulletin.
       
        Change Log
        ====== ===
        E. Safford/SAIC    10/05        initial coding
    -->
    <xsl:template name="OutputFooter">
        
        <xsl:element name="line">
            <xsl:attribute name="indent">0</xsl:attribute>....</xsl:element>
        
        <xsl:element name="line">
            <xsl:attribute name="indent">0</xsl:attribute>NNNN</xsl:element>
        
    </xsl:template>
    
</xsl:stylesheet>
