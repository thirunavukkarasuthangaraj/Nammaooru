package com.shopmanagement.service;

import com.lowagie.text.Document;
import com.lowagie.text.Element;
import com.lowagie.text.Font;
import com.lowagie.text.FontFactory;
import com.lowagie.text.Image;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Phrase;
import com.lowagie.text.Rectangle;
import com.lowagie.text.pdf.BaseFont;
import com.google.zxing.BarcodeFormat;
import com.google.zxing.client.j2se.MatrixToImageWriter;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import com.shopmanagement.entity.Order;
import com.shopmanagement.entity.OrderItem;
import lombok.extern.slf4j.Slf4j;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;

import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Renders a POS order as a branded PDF bill: green shop header,
 * ITEM/MRP/RATE/QTY/AMT table, savings highlight, boxed total,
 * payment method and thank-you footer.
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class BillPdfService {
    private final BillSettingsService billSettingsService;

    private static final DateTimeFormatter DATE_FORMAT = DateTimeFormatter.ofPattern("dd/MM/yyyy hh:mm a");
    private static final ZoneId IST = ZoneId.of("Asia/Kolkata");

    /** Timestamps are stored in server time (UTC); show them in Indian time on the bill. */
    private String formatIst(LocalDateTime serverTime) {
        return serverTime.atZone(ZoneOffset.UTC).withZoneSameInstant(IST).format(DATE_FORMAT);
    }

    private static final Color BRAND_GREEN = new Color(22, 130, 93);
    private static final Color LIGHT_GREEN = new Color(236, 253, 245);
    private static final Color DARK_TEXT = new Color(31, 41, 55);
    private static final Color MUTED_TEXT = new Color(107, 114, 128);
    private static final Color RULE_GRAY = new Color(229, 231, 235);
    private static final Color HEADER_BG = new Color(243, 244, 246);

    private static final float PAGE_WIDTH = 227f;
    private static final float MAX_PAGE_HEIGHT = 6000f;
    private static final float BOTTOM_PADDING = 14f;

    public byte[] generateBillPdf(Order order) {
        // Narrow page like a receipt (80mm wide roll). Pass 1 renders onto a
        // tall throwaway page just to measure how far the content reaches;
        // pass 2 rebuilds the real PDF sized to exactly that height, so
        // short bills don't carry a big blank area below the footer (which
        // pushed the header off-screen on WhatsApp mobile) and long bills
        // never silently overflow onto a second page that never gets sent.
        Map<String, Object> settings = billSettingsService.settingsFor(order.getShop());
        float contentHeight = measureContentHeight(order, settings);
        return renderBill(order, settings, Math.min(contentHeight + BOTTOM_PADDING, MAX_PAGE_HEIGHT));
    }

    /**
     * Render a bill PDF as a JPEG so it shows full-size inline in WhatsApp chat
     * instead of requiring a tap-to-download PDF. Returns null (caller should
     * fall back to sending the PDF) if rendering fails for any reason.
     */
    public byte[] renderBillJpeg(byte[] pdfBytes, String orderNumber) {
        try (org.apache.pdfbox.pdmodel.PDDocument doc =
                     org.apache.pdfbox.pdmodel.PDDocument.load(pdfBytes)) {
            org.apache.pdfbox.rendering.PDFRenderer renderer =
                    new org.apache.pdfbox.rendering.PDFRenderer(doc);
            java.awt.image.BufferedImage image =
                    renderer.renderImageWithDPI(0, 300, org.apache.pdfbox.rendering.ImageType.RGB);

            // Thermal PDFs are initially measured on a very tall page. If that
            // measurement falls back to the safety height, PDFBox faithfully
            // renders thousands of blank pixels below the receipt and WhatsApp
            // scales the useful content into an unreadable vertical strip.
            // Crop only trailing white space; preserve the full receipt width
            // and a small bottom margin.
            image = cropTrailingWhiteSpace(image);

            // Java's default JPEG quality is heavily compressed, which blurs the
            // small receipt text. Force near-lossless quality explicitly.
            javax.imageio.ImageWriter writer = javax.imageio.ImageIO.getImageWritersByFormatName("jpg").next();
            javax.imageio.ImageWriteParam param = writer.getDefaultWriteParam();
            param.setCompressionMode(javax.imageio.ImageWriteParam.MODE_EXPLICIT);
            param.setCompressionQuality(0.95f);

            ByteArrayOutputStream out = new ByteArrayOutputStream();
            try (javax.imageio.stream.ImageOutputStream ios = javax.imageio.ImageIO.createImageOutputStream(out)) {
                writer.setOutput(ios);
                writer.write(null, new javax.imageio.IIOImage(image, null, null), param);
            } finally {
                writer.dispose();
            }
            return out.toByteArray();
        } catch (Exception e) {
            log.warn("Could not render bill {} as image - will send PDF instead: {}", orderNumber, e.getMessage());
            return null;
        }
    }

    private java.awt.image.BufferedImage cropTrailingWhiteSpace(java.awt.image.BufferedImage image) {
        int bottom = image.getHeight() - 1;
        while (bottom > 0 && isBlankImageRow(image, bottom)) {
            bottom--;
        }

        int padding = Math.max(16, image.getWidth() / 40);
        int croppedHeight = Math.min(image.getHeight(), bottom + 1 + padding);
        if (croppedHeight >= image.getHeight()) return image;

        java.awt.image.BufferedImage cropped = new java.awt.image.BufferedImage(
                image.getWidth(), croppedHeight, java.awt.image.BufferedImage.TYPE_INT_RGB);
        java.awt.Graphics2D graphics = cropped.createGraphics();
        try {
            graphics.setColor(java.awt.Color.WHITE);
            graphics.fillRect(0, 0, cropped.getWidth(), cropped.getHeight());
            graphics.drawImage(image, 0, 0, null);
        } finally {
            graphics.dispose();
        }
        return cropped;
    }

    private boolean isBlankImageRow(java.awt.image.BufferedImage image, int y) {
        // Sample every second pixel. Receipt text/borders span enough pixels at
        // 300 DPI that this remains accurate while avoiding a costly full scan.
        for (int x = 0; x < image.getWidth(); x += 2) {
            int rgb = image.getRGB(x, y);
            int red = (rgb >>> 16) & 0xff;
            int green = (rgb >>> 8) & 0xff;
            int blue = rgb & 0xff;
            if (red < 248 || green < 248 || blue < 248) return false;
        }
        return true;
    }

    private float measureContentHeight(Order order, Map<String, Object> settings) {
        Rectangle pageSize = new Rectangle(pageWidth(settings), MAX_PAGE_HEIGHT);
        Document document = new Document(pageSize, 0f, 0f, 0f, 0f);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        try {
            PdfWriter writer = PdfWriter.getInstance(document, out);
            document.open();
            buildContent(document, order, settings);
            float bottomY = writer.getVerticalPosition(true);
            return MAX_PAGE_HEIGHT - bottomY;
        } catch (Exception e) {
            log.warn("Could not measure bill content height for order {}, using max page height: {}",
                    order.getOrderNumber(), e.getMessage());
            return MAX_PAGE_HEIGHT;
        } finally {
            document.close();
        }
    }

    private byte[] renderBill(Order order, Map<String, Object> settings, float pageHeight) {
        Rectangle pageSize = new Rectangle(pageWidth(settings), pageHeight);
        Document document = new Document(pageSize, 0f, 0f, 0f, 0f);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        try {
            PdfWriter.getInstance(document, out);
            document.open();
            buildContent(document, order, settings);
        } catch (Exception e) {
            log.error("Failed to generate bill PDF for order {}", order.getOrderNumber(), e);
            throw new RuntimeException("Failed to generate bill PDF", e);
        } finally {
            document.close();
        }
        return out.toByteArray();
    }

    private static volatile BaseFont TAMIL_BASE_FONT;
    private static volatile java.awt.Font TAMIL_AWT_FONT;
    private static volatile java.awt.Font[] RECEIPT_FALLBACK_FONTS;

    /**
     * Loads (once) a Unicode font covering both Latin and Tamil glyphs.
     * Item/customer names can contain Tamil text, and the built-in PDF
     * standard fonts (Helvetica) only support Latin - Tamil characters
     * would render blank. Falls back to Helvetica if the font can't load.
     */
    private BaseFont tamilBaseFont() throws Exception {
        BaseFont font = TAMIL_BASE_FONT;
        if (font == null) {
            synchronized (BillPdfService.class) {
                font = TAMIL_BASE_FONT;
                if (font == null) {
                    try {
                        byte[] fontBytes = new ClassPathResource("fonts/NotoSansTamil-Regular.ttf")
                                .getInputStream().readAllBytes();
                        font = BaseFont.createFont("NotoSansTamil-Regular.ttf", BaseFont.IDENTITY_H,
                                BaseFont.EMBEDDED, true, fontBytes, null);
                    } catch (Exception e) {
                        log.warn("Could not load Tamil font, falling back to Helvetica: {}", e.getMessage());
                        font = BaseFont.createFont(BaseFont.HELVETICA, BaseFont.WINANSI, BaseFont.NOT_EMBEDDED);
                    }
                    TAMIL_BASE_FONT = font;
                }
            }
        }
        return font;
    }

    private java.awt.Font tamilAwtFont(float size) throws Exception {
        java.awt.Font font = TAMIL_AWT_FONT;
        if (font == null) {
            synchronized (BillPdfService.class) {
                font = TAMIL_AWT_FONT;
                if (font == null) {
                    try (java.io.InputStream input = new ClassPathResource("fonts/NotoSansTamil-Regular.ttf").getInputStream()) {
                        font = java.awt.Font.createFont(java.awt.Font.TRUETYPE_FONT, input);
                    }
                    TAMIL_AWT_FONT = font;
                }
            }
        }
        return font.deriveFont(size);
    }

    /**
     * Fonts available to the raster text shaper, ordered from the bundled Tamil
     * face through the runtime's Noto/system faces. The Docker image installs
     * the Noto families, so this supports other Indic scripts, Arabic, CJK and
     * Cyrillic without product- or language-specific branches.
     */
    private java.awt.Font[] receiptFallbackFonts() throws Exception {
        java.awt.Font[] fonts = RECEIPT_FALLBACK_FONTS;
        if (fonts == null) {
            synchronized (BillPdfService.class) {
                fonts = RECEIPT_FALLBACK_FONTS;
                if (fonts == null) {
                    java.util.List<java.awt.Font> available = new java.util.ArrayList<>();
                    available.add(tamilAwtFont(12f));
                    available.add(new java.awt.Font(java.awt.Font.SANS_SERIF, java.awt.Font.PLAIN, 12));
                    available.addAll(java.util.Arrays.asList(
                            java.awt.GraphicsEnvironment.getLocalGraphicsEnvironment().getAllFonts()));
                    fonts = available.toArray(java.awt.Font[]::new);
                    RECEIPT_FALLBACK_FONTS = fonts;
                }
            }
        }
        return fonts;
    }

    private java.awt.Font receiptFontFor(int codePoint, float size,
                                         java.awt.Font latinFont) throws Exception {
        if (codePoint < 0x80 && latinFont.canDisplay(codePoint)) return latinFont;
        for (java.awt.Font candidate : receiptFallbackFonts()) {
            if (candidate.canDisplay(codePoint)) return candidate.deriveFont(size);
        }
        return latinFont;
    }

    /** Render with Pango/HarfBuzz when available in the production container. */
    private Image renderItemNameWithPango(String text, float fontPixels,
                                          float maxWidthPixels,
                                          float targetWidthPoints) throws Exception {
        java.nio.file.Path executable = java.nio.file.Path.of("/usr/bin/pango-view");
        if (!java.nio.file.Files.isExecutable(executable)) return null;

        java.nio.file.Path output = java.nio.file.Files.createTempFile("receipt-text-", ".png");
        try {
            Process process = new ProcessBuilder(
                    executable.toString(),
                    "--no-display",
                    "--pixels",
                    "--font=Noto Sans " + Math.round(fontPixels),
                    "--width=" + Math.max(1, Math.round(maxWidthPixels)),
                    "--wrap=word-char",
                    "--margin=0",
                    "--background=transparent",
                    "--output=" + output,
                    "--text=" + text)
                    .redirectErrorStream(true)
                    .start();
            boolean completed = process.waitFor(5, java.util.concurrent.TimeUnit.SECONDS);
            if (!completed) {
                process.destroyForcibly();
                throw new java.io.IOException("Pango receipt rendering timed out");
            }
            if (process.exitValue() != 0 || java.nio.file.Files.size(output) == 0) {
                String error = new String(process.getInputStream().readAllBytes(),
                        java.nio.charset.StandardCharsets.UTF_8);
                throw new java.io.IOException("Pango receipt rendering failed: " + error);
            }
            java.awt.image.BufferedImage rendered = javax.imageio.ImageIO.read(output.toFile());
            if (rendered == null) throw new java.io.IOException("Pango returned an invalid image");
            Image image = Image.getInstance(java.nio.file.Files.readAllBytes(output));
            image.scaleToFit(targetWidthPoints, rendered.getHeight() / 3f + 2f);
            return image;
        } finally {
            java.nio.file.Files.deleteIfExists(output);
        }
    }

    /** True for characters in the Tamil Unicode block (U+0B80-U+0BFF). */
    private boolean isTamil(char c) {
        return c >= 0x0B80 && c <= 0x0BFF;
    }

    /**
     * Splits text into same-script runs and renders each with the matching
     * font, so a single font's missing glyphs don't blank out the rest of
     * the line. The bundled Tamil face only covers the Tamil block (it's a
     * script-specific subset, like the one shipped to the frontend) - it
     * has no Latin letters - so English text must stay on the Latin font.
     */
    private Phrase mixedPhrase(String text, Font latinFont, Font tamilFont) {
        Phrase phrase = new Phrase();
        if (text == null || text.isEmpty()) {
            return phrase;
        }
        StringBuilder run = new StringBuilder();
        Boolean runIsTamil = null;
        for (int i = 0; i < text.length(); i++) {
            char c = text.charAt(i);
            boolean tamil = isTamil(c);
            if (runIsTamil != null && tamil != runIsTamil) {
                phrase.add(new com.lowagie.text.Chunk(run.toString(), runIsTamil ? tamilFont : latinFont));
                run.setLength(0);
            }
            run.append(c);
            runIsTamil = tamil;
        }
        if (run.length() > 0) {
            phrase.add(new com.lowagie.text.Chunk(run.toString(), runIsTamil ? tamilFont : latinFont));
        }
        return phrase;
    }

    private void buildContent(Document document, Order order, Map<String, Object> settings) throws Exception {
            BaseFont tamil = tamilBaseFont();
            Color accent = colour(settings);
            Color accentLight = blend(accent, Color.WHITE, 0.86f);
            String template = str(settings, "templateStyle", "classic");
            boolean colouredHeader = "classic".equals(template) || "bold".equals(template)
                    || "compact".equals(template) || "invoice".equals(template);
            Color headerBackground = switch (template) {
                case "invoice" -> new Color(23, 59, 94);
                case "bold" -> blend(accent, new Color(22, 55, 42), 0.28f);
                default -> colouredHeader ? accent : Color.WHITE;
            };
            Color headerText = colouredHeader ? Color.WHITE : DARK_TEXT;
            Font shopFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, num(settings, "headerFontSize", 16), headerText);
            Font headerSubFont = FontFactory.getFont(FontFactory.HELVETICA, Math.max(7, num(settings, "bodyFontSize", 12) - 3), colouredHeader ? Color.WHITE : MUTED_TEXT);
            Font labelFont = FontFactory.getFont(FontFactory.HELVETICA, 7, MUTED_TEXT);
            Font normalFont = FontFactory.getFont(FontFactory.HELVETICA, Math.max(7, num(settings, "bodyFontSize", 12) - 3), DARK_TEXT);
            Font boldFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, Math.max(7, num(settings, "bodyFontSize", 12) - 3), DARK_TEXT);
            Font tableHeadFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 7, MUTED_TEXT);
            Font saveFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 8, accent);
            Font totalFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 13, accent);
            Font footerFont = FontFactory.getFont(FontFactory.HELVETICA, Math.max(6, num(settings, "footerFontSize", 10) - 3), MUTED_TEXT);
            Font thanksFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 9, accent);

            // Tamil-capable counterparts, only for fields that can contain Tamil text
            Font shopFontTamil = new Font(tamil, num(settings, "headerFontSize", 16), Font.BOLD, headerText);
            Font headerSubFontTamil = new Font(tamil, 7, Font.NORMAL, colouredHeader ? Color.WHITE : MUTED_TEXT);
            Font normalFontTamil = new Font(tamil, 8, Font.NORMAL, DARK_TEXT);
            Font boldFontTamil = new Font(tamil, 8, Font.BOLD, DARK_TEXT);

            // ===== Green brand header =====
            PdfPTable header = new PdfPTable(1);
            header.setWidthPercentage(100);
            PdfPCell headerCell = new PdfPCell();
            headerCell.setBackgroundColor(headerBackground);
            headerCell.setBorder("bordered".equals(template) ? Rectangle.BOX : Rectangle.NO_BORDER);
            headerCell.setBorderColor(accent);
            headerCell.setPaddingTop(12f);
            headerCell.setPaddingBottom(12f);
            headerCell.setPaddingLeft(12f);
            headerCell.setPaddingRight(12f);

            if (bool(settings, "showShopName", true)) {
                Paragraph shopName = new Paragraph();
                shopName.add(mixedPhrase(str(settings, "shopName", order.getShop().getName()), shopFont, shopFontTamil));
                shopName.setAlignment(Element.ALIGN_CENTER); headerCell.addElement(shopName);
            }

            String shopLine = str(settings, "shopAddress", joinNonBlank(order.getShop().getAddressLine1(), order.getShop().getCity()));
            if (bool(settings, "showShopAddress", false) && !shopLine.isEmpty()) {
                Paragraph addr = new Paragraph();
                addr.add(mixedPhrase(shopLine, headerSubFont, headerSubFontTamil));
                addr.setAlignment(Element.ALIGN_CENTER);
                headerCell.addElement(addr);
            }
            String configuredPhone = str(settings, "shopPhone", order.getShop().getOwnerPhone());
            if (bool(settings, "showShopPhone", true) && !configuredPhone.isBlank()) {
                Paragraph phone = new Paragraph("Ph: " + configuredPhone, headerSubFont);
                phone.setAlignment(Element.ALIGN_CENTER);
                headerCell.addElement(phone);
            }
            if (bool(settings, "showGstNumber", false) && !str(settings, "gstNumber", "").isBlank())
                headerCell.addElement(centered("GSTIN: " + str(settings, "gstNumber", ""), headerSubFont));
            if (bool(settings, "showFssaiInfo", false) && !str(settings, "fssaiNumber", "").isBlank())
                headerCell.addElement(centered("FSSAI: " + str(settings, "fssaiNumber", ""), headerSubFont));
            header.addCell(headerCell);
            document.add(header);

            // ===== Body (padded) =====
            PdfPTable body = new PdfPTable(1);
            body.setWidthPercentage(100);
            PdfPCell bodyCell = new PdfPCell();
            bodyCell.setBorder(Rectangle.NO_BORDER);
            bodyCell.setPaddingLeft(12f);
            bodyCell.setPaddingRight(12f);
            bodyCell.setPaddingTop(8f);

            // Bill meta: number + date, customer
            PdfPTable meta = new PdfPTable(new float[]{1f, 1f});
            meta.setWidthPercentage(100);
            addCell(meta, bool(settings,"showBillNumber",true) ? "Bill No" : "", labelFont, Element.ALIGN_LEFT);
            addCell(meta, bool(settings,"showDateTime",true) ? "Date" : "", labelFont, Element.ALIGN_RIGHT);
            addCell(meta, bool(settings,"showBillNumber",true) ? str(settings,"billNumberPrefix","") + order.getOrderNumber() : "", boldFont, Element.ALIGN_LEFT);
            addCell(meta, bool(settings,"showDateTime",true) ? formatDate(order.getCreatedAt(), settings) : "", normalFont, Element.ALIGN_RIGHT);
            bodyCell.addElement(meta);

            String customerName = displayCustomerName(order);
            String customerPhone = order.getCustomer() != null ? order.getCustomer().getMobileNumber() : null;
            if (bool(settings, "showCustomerDetails", true) && (customerName != null || customerPhone != null)) {
                bodyCell.addElement(spacer(4f));
                Paragraph custLabel = new Paragraph("Billed To", labelFont);
                bodyCell.addElement(custLabel);
                String custLine = joinNonBlank(customerName, customerPhone);
                Paragraph custPara = new Paragraph();
                custPara.add(mixedPhrase(custLine, boldFont, boldFontTamil));
                bodyCell.addElement(custPara);
            }

            bodyCell.addElement(spacer(6f));
            bodyCell.addElement(rule());

            // ===== Items table =====
            List<String> columns = new ArrayList<>(List.of("ITEM"));
            if (bool(settings,"showItemSku",false)) columns.add("SKU");
            if (bool(settings,"showItemBarcode",false)) columns.add("CODE");
            if (bool(settings,"showItemMrp",true)) columns.add("MRP");
            if (bool(settings,"showSellingPrice",true)) columns.add("RATE");
            if (bool(settings,"showItemDiscount",true)) columns.add("DISC");
            columns.add("QTY"); columns.add("AMT");
            float[] widths = new float[columns.size()]; widths[0] = 4f;
            for (int x = 1; x < widths.length; x++) widths[x] = columns.get(x).equals("QTY") ? 1f : 1.4f;
            PdfPTable table = new PdfPTable(widths);
            table.setWidthPercentage(100);
            for (String column : columns) addHeadCell(table, column, tableHeadFont, column.equals("ITEM") ? Element.ALIGN_LEFT : Element.ALIGN_RIGHT);

            BigDecimal mrpTotal = BigDecimal.ZERO;
            int totalQty = 0;
            for (OrderItem item : order.getOrderItems()) {
                BigDecimal mrp = resolveMrp(item);
                BigDecimal lineMrp = mrp.multiply(BigDecimal.valueOf(item.getQuantity()));
                mrpTotal = mrpTotal.add(lineMrp);
                totalQty += item.getQuantity();

                boolean showEnglish = bool(settings, "showEnglish", true);
                boolean showTamil = bool(settings, "showTamil", true);
                String itemName = showEnglish ? item.getProductName() : "";
                if (showTamil && item.getProductNameTamil() != null) itemName = joinNonBlank(itemName, item.getProductNameTamil());
                if (itemName == null || itemName.isBlank()) itemName = "Item";
                float widthSum = 0f;
                for (float width : widths) widthSum += width;
                float itemColumnWidth = Math.max(45f, pageWidth(settings) * widths[0] / widthSum - 5f);
                addItemNameCell(table, itemName, normalFont, normalFontTamil, itemColumnWidth);
                for (String column : columns.subList(1, columns.size())) {
                    String value = switch (column) {
                        case "SKU" -> item.getProductSku() == null ? "" : item.getProductSku();
                        case "CODE" -> itemBarcode(item);
                        case "MRP" -> stripZeros(mrp); case "RATE" -> stripZeros(item.getUnitPrice());
                        case "DISC" -> stripZeros(mrp.subtract(item.getUnitPrice()).max(BigDecimal.ZERO));
                        case "QTY" -> String.valueOf(item.getQuantity()); default -> stripZeros(item.getTotalPrice());
                    };
                    addCell(table, value, column.equals("AMT") ? boldFont : normalFont, Element.ALIGN_RIGHT);
                }
            }
            bodyCell.addElement(table);

            bodyCell.addElement(rule());
            bodyCell.addElement(spacer(4f));

            // ===== Totals =====
            PdfPTable totals = new PdfPTable(new float[]{3f, 2f});
            totals.setWidthPercentage(100);
            if (bool(settings,"showSubtotal",true)) {
                addCell(totals, "Items: " + order.getOrderItems().size() + " (Qty: " + totalQty + ")", normalFont, Element.ALIGN_LEFT);
                addCell(totals, "Rs. " + stripZeros(order.getSubtotal()), normalFont, Element.ALIGN_RIGHT);
            }

            BigDecimal savings = mrpTotal.subtract(order.getSubtotal());
            if (bool(settings,"showTotalSavings",true) && savings.signum() > 0) {
                addCell(totals, "MRP Total", labelFont, Element.ALIGN_LEFT);
                addCell(totals, "Rs. " + stripZeros(mrpTotal), labelFont, Element.ALIGN_RIGHT);
                addCell(totals, "You Save", saveFont, Element.ALIGN_LEFT);
                addCell(totals, "Rs. " + stripZeros(savings), saveFont, Element.ALIGN_RIGHT);
            }
            // Not gated on a display toggle: a discount that changed the total must be
            // visible on the bill, or the customer sees an unexplained jump in TOTAL.
            if (order.getDiscountAmount() != null && order.getDiscountAmount().signum() > 0) {
                addCell(totals, "Discount", normalFont, Element.ALIGN_LEFT);
                addCell(totals, "- Rs. " + stripZeros(order.getDiscountAmount()), normalFont, Element.ALIGN_RIGHT);
            }
            if (bool(settings,"showTaxBreakdown",false) && order.getTaxAmount() != null && order.getTaxAmount().signum() > 0) {
                addCell(totals, "Tax", normalFont, Element.ALIGN_LEFT);
                addCell(totals, "Rs. " + stripZeros(order.getTaxAmount()), normalFont, Element.ALIGN_RIGHT);
            }
            bodyCell.addElement(totals);

            bodyCell.addElement(spacer(6f));

            // ===== Boxed grand total =====
            PdfPTable grand = new PdfPTable(new float[]{1f, 1f});
            grand.setWidthPercentage(100);
            PdfPCell totalLabel = new PdfPCell(new Phrase("TOTAL", totalFont));
            totalLabel.setBackgroundColor(accentLight);
            totalLabel.setBorder(Rectangle.NO_BORDER);
            totalLabel.setPadding(8f);
            totalLabel.setHorizontalAlignment(Element.ALIGN_LEFT);
            grand.addCell(totalLabel);
            PdfPCell totalValue = new PdfPCell(new Phrase("Rs. " + stripZeros(order.getTotalAmount()), totalFont));
            totalValue.setBackgroundColor(accentLight);
            totalValue.setBorder(Rectangle.NO_BORDER);
            totalValue.setPadding(8f);
            totalValue.setHorizontalAlignment(Element.ALIGN_RIGHT);
            grand.addCell(totalValue);
            bodyCell.addElement(grand);

            if (bool(settings,"showPaymentMethod",true) && order.getPaymentMethod() != null) {
                bodyCell.addElement(spacer(4f));
                Paragraph pay = new Paragraph("Paid by: " + order.getPaymentMethod().name().replace("_", " "),
                        boldFont);
                pay.setAlignment(Element.ALIGN_CENTER);
                bodyCell.addElement(pay);
            }

            String upiId = str(settings, "upiId", order.getShop().getUpiId());
            if (bool(settings, "showUpiQrCode", false) && !upiId.isBlank()) {
                bodyCell.addElement(spacer(6f));
                String upiUri = "upi://pay?pa=" + upiId + "&pn="
                        + java.net.URLEncoder.encode(str(settings, "shopName", order.getShop().getName()), java.nio.charset.StandardCharsets.UTF_8)
                        + "&am=" + stripZeros(order.getTotalAmount()) + "&cu=INR";
                BitMatrix matrix = new QRCodeWriter().encode(upiUri, BarcodeFormat.QR_CODE, 160, 160);
                ByteArrayOutputStream qrBytes = new ByteArrayOutputStream();
                MatrixToImageWriter.writeToStream(matrix, "PNG", qrBytes);
                Image qrImage = Image.getInstance(qrBytes.toByteArray());
                qrImage.scaleAbsolute(62f, 62f); qrImage.setAlignment(Element.ALIGN_CENTER);
                bodyCell.addElement(qrImage);
                bodyCell.addElement(centered(upiId, footerFont));
            }

            bodyCell.addElement(spacer(8f));
            if (bool(settings,"showThankYouMessage",true))
                bodyCell.addElement(centered(str(settings,"thankYouMessage","Thank you for your order!"), thanksFont));

            if (!str(settings,"footerNote","").isBlank()) bodyCell.addElement(centered(str(settings,"footerNote",""), footerFont));

            Paragraph printed = new Paragraph("Printed: " + formatIst(order.getCreatedAt()), footerFont);
            printed.setAlignment(Element.ALIGN_CENTER);
            bodyCell.addElement(printed);

            Paragraph powered = new Paragraph("Powered by Namma Ooru Connect", footerFont);
            powered.setAlignment(Element.ALIGN_CENTER);
            bodyCell.addElement(powered);

            body.addCell(bodyCell);
            document.add(body);
    }

    /**
     * Customer name for display: drops the "POS" placeholder last name and
     * collapses duplicated first/last names ("Thiru Thiru" -> "Thiru").
     */
    private String displayCustomerName(Order order) {
        if (order.getCustomer() == null) return null;
        String first = order.getCustomer().getFirstName();
        String last = order.getCustomer().getLastName();
        first = first == null ? "" : first.trim();
        last = last == null ? "" : last.trim();
        if (last.isEmpty() || "POS".equalsIgnoreCase(last) || last.equalsIgnoreCase(first)) {
            return first.isEmpty() ? null : first;
        }
        return (first + " " + last).trim();
    }

    private String joinNonBlank(String... parts) {
        StringBuilder sb = new StringBuilder();
        for (String part : parts) {
            if (part != null && !part.isBlank()) {
                if (sb.length() > 0) sb.append(", ");
                sb.append(part.trim());
            }
        }
        return sb.toString();
    }

    private Paragraph spacer(float height) {
        Paragraph p = new Paragraph(" ", FontFactory.getFont(FontFactory.HELVETICA, 2));
        p.setSpacingBefore(height / 2);
        p.setSpacingAfter(height / 2);
        return p;
    }

    /** Thin light-gray horizontal rule (bordered empty table row). */
    private PdfPTable rule() {
        PdfPTable line = new PdfPTable(1);
        line.setWidthPercentage(100);
        line.setSpacingBefore(3f);
        line.setSpacingAfter(3f);
        PdfPCell cell = new PdfPCell(new Phrase(" ", FontFactory.getFont(FontFactory.HELVETICA, 1)));
        cell.setBorder(Rectangle.BOTTOM);
        cell.setBorderColor(RULE_GRAY);
        cell.setBorderWidth(0.75f);
        cell.setFixedHeight(2f);
        line.addCell(cell);
        return line;
    }

    /** MRP from the product's original price; falls back to selling rate when absent. */
    private BigDecimal resolveMrp(OrderItem item) {
        try {
            if (item.getShopProduct() != null && item.getShopProduct().getOriginalPrice() != null
                    && item.getShopProduct().getOriginalPrice().signum() > 0) {
                return item.getShopProduct().getOriginalPrice();
            }
        } catch (Exception ignored) {
            // lazy-loading may fail outside a session; fall back to unit price
        }
        return item.getUnitPrice();
    }

    private String stripZeros(BigDecimal value) {
        if (value == null) return "0";
        BigDecimal stripped = value.stripTrailingZeros();
        if (stripped.scale() < 0) {
            stripped = stripped.setScale(0);
        }
        return stripped.toPlainString();
    }

    private void addCell(PdfPTable table, String text, Font font, int align) {
        PdfPCell cell = new PdfPCell(new Paragraph(text, font));
        cell.setBorder(Rectangle.NO_BORDER);
        cell.setHorizontalAlignment(align);
        cell.setPaddingTop(2f);
        cell.setPaddingBottom(2f);
        table.addCell(cell);
    }

    /** Like addCell, but splits Latin/Tamil runs across two fonts (see mixedPhrase). */
    private void addCellMixed(PdfPTable table, String text, Font latinFont, Font tamilFont, int align) {
        Paragraph para = new Paragraph();
        para.add(mixedPhrase(text, latinFont, tamilFont));
        PdfPCell cell = new PdfPCell(para);
        cell.setBorder(Rectangle.NO_BORDER);
        cell.setHorizontalAlignment(align);
        cell.setPaddingTop(2f);
        cell.setPaddingBottom(2f);
        table.addCell(cell);
    }

    /**
     * OpenPDF does not perform complex-script shaping. Render every product name
     * with Java2D TextLayout and Unicode font fallback, then place the lossless
     * result in the PDF. This handles mixed scripts and bidirectional text before
     * PDFBox converts the receipt to the WhatsApp JPG.
     */
    private void addItemNameCell(PdfPTable table, String text, Font latinPdfFont,
                                 Font tamilPdfFont, float targetWidthPoints) throws Exception {
        // Product names can arrive from imports/keyboards in canonically-decomposed
        // form (for example a Tamil vowel sign represented by multiple code points).
        // Normalize before measuring and shaping so those marks stay attached to
        // their base consonant in the PDF and in the JPG rendered from that PDF.
        text = text == null ? null : java.text.Normalizer.normalize(
                text, java.text.Normalizer.Form.NFC);
        if (text == null || text.isBlank()) text = "Item";

        final float scale = 3f;
        final float fontPixels = Math.max(24f, latinPdfFont.getSize() * scale);
        final float maxWidthPixels = targetWidthPoints * scale;
        java.awt.Font latinFont = new java.awt.Font(java.awt.Font.SANS_SERIF, java.awt.Font.PLAIN,
                Math.round(fontPixels));

        // Pango uses HarfBuzz and FriBidi, providing reliable complex-script
        // shaping and directionality. Java2D below remains a local/dev fallback.
        Image pangoImage = null;
        try {
            pangoImage = renderItemNameWithPango(
                    text, fontPixels, maxWidthPixels, targetWidthPoints);
        } catch (Exception e) {
            log.warn("Pango receipt shaping failed; using Java2D fallback: {}", e.getMessage());
        }
        if (pangoImage != null) {
            PdfPCell cell = new PdfPCell(pangoImage, false);
            cell.setBorder(Rectangle.NO_BORDER);
            cell.setHorizontalAlignment(Element.ALIGN_LEFT);
            cell.setPaddingTop(2f);
            cell.setPaddingBottom(2f);
            table.addCell(cell);
            return;
        }

        java.text.AttributedString attributed = new java.text.AttributedString(text);
        attributed.addAttribute(java.awt.font.TextAttribute.FONT, latinFont);
        int runStart = 0;
        java.awt.Font runFont = null;
        for (int offset = 0; offset < text.length();) {
            int codePoint = text.codePointAt(offset);
            java.awt.Font font = receiptFontFor(codePoint, fontPixels, latinFont);
            if (runFont != null && !runFont.getFontName().equals(font.getFontName())) {
                attributed.addAttribute(java.awt.font.TextAttribute.FONT, runFont, runStart, offset);
                runStart = offset;
            }
            runFont = font;
            offset += Character.charCount(codePoint);
        }
        if (runFont != null) {
            attributed.addAttribute(java.awt.font.TextAttribute.FONT, runFont, runStart, text.length());
        }

        java.awt.font.FontRenderContext context = new java.awt.font.FontRenderContext(null, true, true);
        java.awt.font.LineBreakMeasurer measurer = new java.awt.font.LineBreakMeasurer(
                attributed.getIterator(), context);
        java.util.List<java.awt.font.TextLayout> layouts = new java.util.ArrayList<>();
        float height = 0f;
        while (measurer.getPosition() < text.length()) {
            java.awt.font.TextLayout layout = measurer.nextLayout(maxWidthPixels);
            layouts.add(layout);
            height += layout.getAscent() + layout.getDescent() + layout.getLeading();
        }

        int imageWidth = Math.max(1, (int) Math.ceil(maxWidthPixels));
        int imageHeight = Math.max(1, (int) Math.ceil(height + 4f));
        java.awt.image.BufferedImage rendered = new java.awt.image.BufferedImage(
                imageWidth, imageHeight, java.awt.image.BufferedImage.TYPE_INT_ARGB);
        java.awt.Graphics2D graphics = rendered.createGraphics();
        try {
            graphics.setRenderingHint(java.awt.RenderingHints.KEY_TEXT_ANTIALIASING,
                    java.awt.RenderingHints.VALUE_TEXT_ANTIALIAS_ON);
            graphics.setColor(java.awt.Color.BLACK);
            float y = 0f;
            for (java.awt.font.TextLayout layout : layouts) {
                y += layout.getAscent();
                layout.draw(graphics, 0f, y);
                y += layout.getDescent() + layout.getLeading();
            }
        } finally {
            graphics.dispose();
        }

        ByteArrayOutputStream png = new ByteArrayOutputStream();
        javax.imageio.ImageIO.write(rendered, "PNG", png);
        Image nameImage = Image.getInstance(png.toByteArray());
        nameImage.scaleToFit(targetWidthPoints, imageHeight / scale + 2f);
        PdfPCell cell = new PdfPCell(nameImage, false);
        cell.setBorder(Rectangle.NO_BORDER);
        cell.setHorizontalAlignment(Element.ALIGN_LEFT);
        cell.setPaddingTop(2f);
        cell.setPaddingBottom(2f);
        table.addCell(cell);
    }

    private void addHeadCell(PdfPTable table, String text, Font font, int align) {
        PdfPCell cell = new PdfPCell(new Paragraph(text, font));
        cell.setBorder(Rectangle.NO_BORDER);
        cell.setBackgroundColor(HEADER_BG);
        cell.setHorizontalAlignment(align);
        cell.setPaddingTop(3f);
        cell.setPaddingBottom(3f);
        cell.setPaddingLeft(2f);
        cell.setPaddingRight(2f);
        table.addCell(cell);
    }

    private boolean bool(Map<String, Object> settings, String key, boolean fallback) {
        Object value = settings.get(key);
        return value instanceof Boolean b ? b : value == null ? fallback : Boolean.parseBoolean(value.toString());
    }

    private int num(Map<String, Object> settings, String key, int fallback) {
        Object value = settings.get(key);
        if (value instanceof Number n) return n.intValue();
        try { return value == null ? fallback : Integer.parseInt(value.toString()); }
        catch (NumberFormatException ignored) { return fallback; }
    }

    private String str(Map<String, Object> settings, String key, String fallback) {
        Object value = settings.get(key);
        return value == null ? (fallback == null ? "" : fallback) : value.toString();
    }

    private float pageWidth(Map<String, Object> settings) {
        return switch (str(settings, "paperWidth", "80mm")) {
            case "58mm" -> 164f;
            case "A4" -> 595f;
            default -> PAGE_WIDTH;
        };
    }

    private Color colour(Map<String, Object> settings) {
        try { return Color.decode(str(settings, "accentColor", "#16825d")); }
        catch (NumberFormatException ignored) { return BRAND_GREEN; }
    }

    private Color blend(Color a, Color b, float amountOfB) {
        float x = Math.max(0, Math.min(1, amountOfB));
        return new Color(Math.round(a.getRed() * (1-x) + b.getRed() * x),
                Math.round(a.getGreen() * (1-x) + b.getGreen() * x),
                Math.round(a.getBlue() * (1-x) + b.getBlue() * x));
    }

    private Paragraph centered(String text, Font font) {
        Paragraph paragraph = new Paragraph(text, font);
        paragraph.setAlignment(Element.ALIGN_CENTER);
        return paragraph;
    }

    private String formatDate(LocalDateTime serverTime, Map<String, Object> settings) {
        String pattern = switch (str(settings, "dateFormat", "DD/MM/YYYY")) {
            case "MM/DD/YYYY" -> "MM/dd/yyyy hh:mm a";
            case "YYYY-MM-DD" -> "yyyy-MM-dd hh:mm a";
            default -> "dd/MM/yyyy hh:mm a";
        };
        return serverTime.atZone(ZoneOffset.UTC).withZoneSameInstant(IST).format(DateTimeFormatter.ofPattern(pattern));
    }

    private String itemBarcode(OrderItem item) {
        try {
            return item.getShopProduct() == null || item.getShopProduct().getBarcode1() == null
                    ? "" : item.getShopProduct().getBarcode1();
        } catch (Exception ignored) { return ""; }
    }
}
