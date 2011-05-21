<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:output method="xml" indent="yes"/>

	<xsl:template match="//PAGE">
		<xsl:call-template name="t1"/>
	</xsl:template>

	<xsl:template name="t1">

		<xsl:variable name="pageWidth">
			<xsl:value-of select="self::*/@width"/>
		</xsl:variable>

		<xsl:variable name="pageHeight">
			<xsl:value-of select="self::*/@height"/>
		</xsl:variable>

		<page>

			<xsl:attribute name="n">
				<xsl:value-of select="round(self::*/@number)"/>
			</xsl:attribute>

			<xsl:for-each select="descendant::TOKEN">

				<xsl:variable name="x">
					<xsl:value-of select="round(self::*/@x * 1000 div $pageWidth)"/>
				</xsl:variable>

				<xsl:variable name="y">
					<xsl:value-of select="round(self::*/@y * 1000 div $pageHeight)"/>
				</xsl:variable>

				<xsl:variable name="w">
					<xsl:value-of select="round(self::*/@width * 1000 div $pageWidth)"/>
				</xsl:variable>

				<xsl:variable name="h">
					<xsl:value-of select="round(self::*/@height * 1000 div $pageHeight)"/>
				</xsl:variable>

				<w>
			
					<xsl:attribute name="c">
  						<xsl:value-of select="concat($x, ',', $y, ',', $w, ',', $h)"/>
						</xsl:attribute>

					<xsl:value-of select="."/>
					
				</w>
			
			</xsl:for-each>

		</page>

	</xsl:template>

</xsl:stylesheet>