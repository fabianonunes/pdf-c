<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:output method="xml" indent="yes"/>

	<xsl:param name="inputFile">-</xsl:param>

	<xsl:template match="/">
		<xsl:call-template name="t1"/>
	</xsl:template>

	<xsl:template name="t1">

		<pdfxml>

		<xsl:for-each select="//PAGE">

			<xsl:variable name="pageWidth">
				<xsl:value-of select="round(self::*/@width)"/>
			</xsl:variable>

			<xsl:variable name="pageHeight">
				<xsl:value-of select="round(self::*/@height)"/>
			</xsl:variable>

			<page>

				<xsl:attribute name="n">
					<xsl:value-of select="round(self::*/@number)"/>
   				</xsl:attribute>

				<xsl:attribute name="w">
      				<xsl:value-of select="$pageWidth"/>
   				</xsl:attribute>

				<xsl:attribute name="h">
      				<xsl:value-of select="$pageHeight"/>
   				</xsl:attribute>

   				<xsl:for-each select="descendant::TEXT">

   					<tk>

						<xsl:attribute name="x">
							<xsl:value-of select="round(self::*/@x)"/>
		   				</xsl:attribute>

						<xsl:attribute name="y">
							<xsl:value-of select="round(self::*/@y)"/>
		   				</xsl:attribute>

						<xsl:attribute name="w">
							<xsl:value-of select="round(self::*/@width)"/>
		   				</xsl:attribute>

						<xsl:attribute name="h">
							<xsl:value-of select="round(self::*/@height)"/>
		   				</xsl:attribute>

						<xsl:attribute name="ws">
 							<xsl:call-template name="join">
								<xsl:with-param name="valueList" select="descendant::TOKEN/@width"/>
								<xsl:with-param name="separator" select="','"/>
							</xsl:call-template>
		   				</xsl:attribute>

   						<xsl:value-of select="normalize-space(.)"/>

   						<xsl:for-each select="descendant::TOKEN">

   						</xsl:for-each>

   					</tk>
   				
   				</xsl:for-each>

			</page>

		</xsl:for-each>

		</pdfxml>

	</xsl:template>

	<xsl:template name="join" >

		<xsl:param name="valueList" select="''"/>
		<xsl:param name="separator" select="','"/>

		<xsl:for-each select="$valueList">
			<xsl:choose>
				<xsl:when test="position() = 1">
					<xsl:value-of select="round(.)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="concat($separator, round(.)) "/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>

	</xsl:template>
		

</xsl:stylesheet>