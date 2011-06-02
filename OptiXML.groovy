import java.io.BufferedOutputStream
import java.io.File
import java.io.FileOutputStream
import java.util.zip.GZIPOutputStream

import org.apache.commons.lang.StringEscapeUtils
import org.apache.commons.lang.StringUtils

import com.ximpleware.AutoPilot
import com.ximpleware.FastLongBuffer
import com.ximpleware.ModifyException
import com.ximpleware.NavException
import com.ximpleware.PilotException
import com.ximpleware.VTDGen
import com.ximpleware.VTDNav
import com.ximpleware.XMLModifier
import com.ximpleware.XPathParseException

@Grab(group="net.sf.vtd-xml", module="vtd-xml", version="2.10")
@Grab(group="commons-lang", module="commons-lang", version="2.5")
class OptiXML {

	private File file;
	private AutoPilot ap;
	private VTDNav nav;
	
	

	static void main(def args){

		def o = new OptiXML();

		o.run(args);
	}

	void run(def args){

		def vg = new VTDGen();

		def xm = new XMLModifier();
		def simple = new XMLModifier();
		
		file = new File(args[0]);
		
		if (vg.parseFile(args[0], false)) {

			nav = vg.getNav();

			xm.bind(nav);
			xm.updateElementName("full");

			simple.bind(nav);
			simple.updateElementName("pdfxml");

			ap = new AutoPilot(nav);

			ap.selectXPath("//PAGE");

			int t;


			while (ap.evalXPath() != -1) {

				xm.updateElementName("page");
				simple.updateElementName("page");

				// width
				String name = "width";
				t = nav.getAttrVal(name);
				Float pageWidth = nav.parseFloat(t);
				simple.updateToken(t, Integer.toString(pageWidth.intValue()));
				ap.selectAttr(name);

				t = ap.iterateAttr();
				xm.removeAttribute(t);
				simple.updateToken(t, "w");
				// height
				name = "height";
				t = nav.getAttrVal(name);
				Float pageHeight = nav.parseFloat(t);
				simple.updateToken(t, Integer.toString(pageHeight.intValue()));
				ap.selectAttr(name);
				t = ap.iterateAttr();
				xm.removeAttribute(t);
				simple.updateToken(t, "h");
				//
				removeAttr("id", xm);
				removeAttr("id", simple);
				ap.selectAttr("number");
				t = ap.iterateAttr();
				xm.updateToken(t, "n");
				simple.updateToken(t, "n");
				t = nav.getAttrVal("number");
				if (t == -1)
					continue;
				if (!nav.toElement(VTDNav.FIRST_CHILD)) {
					continue;
				}
				boolean hasNext = true;

				while (!nav.matchElement("TEXT") && hasNext) {
					xm.remove();
					simple.remove();
					hasNext = nav.toElement(VTDNav.NEXT_SIBLING);
				}

				if (!hasNext) {
					continue;
				}

				while(true) {
					// simple
					simple.updateElementName("tk");
					name = "width";
					t = nav.getAttrVal(name);
					Float textWidth = nav.parseFloat(t);
					simple.updateToken(t,
							Integer.toString(textWidth.intValue()));
					ap.selectAttr(name);
					t = ap.iterateAttr();
					simple.updateToken(t, "w");
					name = "height";
					t = nav.getAttrVal(name);
					Float textHeight = nav.parseFloat(t);
					simple.updateToken(t,
							Integer.toString(textHeight.intValue()));
					ap.selectAttr(name);
					t = ap.iterateAttr();
					simple.updateToken(t, "h");
					name = "x";
					t = nav.getAttrVal(name);
					Float textX = nav.parseFloat(t);
					simple.updateToken(t, Integer.toString(textX.intValue()));
					ap.selectAttr(name);
					t = ap.iterateAttr();
					simple.updateToken(t, "x");
					name = "y";
					t = nav.getAttrVal(name);
					Float textY = nav.parseFloat(t);
					simple.updateToken(t, Integer.toString(textY.intValue()));
					ap.selectAttr(name);
					t = ap.iterateAttr();
					simple.updateToken(t, "y");
					ap.selectAttr("id");
					t = ap.iterateAttr();
					simple.removeAttribute(t);
					List<String> ws = new ArrayList<String>();
					List<String> text = new ArrayList<String>();

					if (nav.toElement(VTDNav.FIRST_CHILD)) {

						StringBuffer data = new StringBuffer();

						while(true) {
							simple.remove();
							t = nav.getAttrVal("x");
							Float left = nav.parseFloat(t);
							t = nav.getAttrVal("y");
							Float top = nav.parseFloat(t);
							t = nav.getAttrVal("width");
							Float width = nav.parseFloat(t);
							t = nav.getAttrVal("height");
							Float height = nav.parseFloat(t);
							int iX = Math.round(left * 1000 / pageWidth);
							int iY = Math.round(top * 1000 / pageHeight);
							int iW = Math.round(width * 1000 / pageWidth);
							int iH = Math.round(height * 1000 / pageHeight);
							// x,y,w,h
							String coords = iX + "," + iY + "," + iW + "," + iH;
							// lw
							int wleft = Math.round(left);
							int wwidth = Math.round(width);
							ws.add(wleft + "," + wwidth);
							t = nav.getText();
							String tokenText = nav.toNormalizedString(t);
							tokenText = StringEscapeUtils.escapeXml(tokenText)
									.replace("&apos;", "'");
							text.add(tokenText.trim());
							data.append("<w c=\"" + coords + "\">" + tokenText
									+ "</w>\n\t");

							if(!nav.toElement(VTDNav.NEXT_SIBLING)){
								break;
							}

						}

						nav.toElement(VTDNav.PARENT);
						xm.insertAfterElement(data.toString().getBytes());

					}

					simple.insertAttribute(" ws=\"" + StringUtils.join(ws, ",")
							+ "\" ");

					simple.insertAfterHead(StringUtils.join(text, " "));

					// opti
					xm.remove();

					if(!nav.toElement(VTDNav.NEXT_SIBLING)){
						break;
					}

				}

				nav.toElement(VTDNav.PARENT);

			}

			ap.resetXPath();
			vg.clear();

			File outFile = new File(file.getParentFile(), "opti.xml");
			FileOutputStream optiOS = new FileOutputStream(outFile);

			splitSimple(simple.outputAndReparse());
			xm.output(optiOS);

		}
	}

	void splitSimple(VTDNav nav) {

		AutoPilot ap = new AutoPilot();

		ap.selectXPath("//page");

		ap.bind(nav);

		byte[] xml = nav.getXML().getBytes();

		while (ap.evalXPath() != -1) {

			FastLongBuffer flb = new FastLongBuffer(4);

			flb.append(nav.getElementFragment());

			int t = nav.getAttrVal("n");

			if (t == -1) {
				continue;
			}

			String pageNumber = nav.toNormalizedString(t).trim();

			File parentFolder = new File(file.getParentFile(), "simple");
			parentFolder.mkdir();

			File destFile = new File(parentFolder, pageNumber + ".xml.gz");

			BufferedOutputStream gos = new BufferedOutputStream(
					new GZIPOutputStream(new FileOutputStream(destFile)));

			gos.write("<pdfxml>\n".getBytes());

			int size = flb.size();

			for (int k = 0; k < size; k++) {

				gos.write("\n".getBytes());

				gos.write(xml, flb.lower32At(k), flb.upper32At(k));

			}

			gos.write("\n</pdfxml>".getBytes());

			gos.close();

			flb.clear();

		}

		ap.resetXPath();

	}

	public Integer getNumberOfLeafs() throws XPathParseException {

		String query = "//page[last()]/@n";

		AutoPilot ap = new AutoPilot(nav);

		ap.selectXPath(query);

		return Integer.parseInt(ap.evalXPathToString());

	}

	private void removeAttr(String attr, XMLModifier xm) throws PilotException,
	NavException, ModifyException {

		ap.selectAttr(attr);
		int t = ap.iterateAttr();
		xm.removeAttribute(t);

	}

}
