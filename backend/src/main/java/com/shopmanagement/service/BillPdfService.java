package com.shopmanagement.service;

import com.lowagie.text.Document;
import com.lowagie.text.Element;
import com.lowagie.text.Font;
import com.lowagie.text.FontFactory;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Phrase;
import com.lowagie.text.Rectangle;
import com.lowagie.text.pdf.BaseFont;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import com.shopmanagement.entity.Order;
import com.shopmanagement.entity.OrderItem;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;

import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;

/**
 * Renders a POS order as a branded PDF bill: green shop header,
 * ITEM/MRP/RATE/QTY/AMT table, savings highlight, boxed total,
 * payment method and thank-you footer.
 */
@Service
@Slf4j
public class BillPdfService {

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
        float contentHeight = measureContentHeight(order);
        return renderBill(order, Math.min(contentHeight + BOTTOM_PADDING, MAX_PAGE_HEIGHT));
    }

    private float measureContentHeight(Order order) {
        Rectangle pageSize = new Rectangle(PAGE_WIDTH, MAX_PAGE_HEIGHT);
        Document document = new Document(pageSize, 0f, 0f, 0f, 0f);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        try {
            PdfWriter writer = PdfWriter.getInstance(document, out);
            document.open();
            buildContent(document, order);
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

    private byte[] renderBill(Order order, float pageHeight) {
        Rectangle pageSize = new Rectangle(PAGE_WIDTH, pageHeight);
        Document document = new Document(pageSize, 0f, 0f, 0f, 0f);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        try {
            PdfWriter.getInstance(document, out);
            document.open();
            buildContent(document, order);
        } catch (Exception e) {
            log.error("Failed to generate bill PDF for order {}", order.getOrderNumber(), e);
            throw new RuntimeException("Failed to generate bill PDF", e);
        } finally {
            document.close();
        }
        return out.toByteArray();
    }

    private static volatile BaseFont TAMIL_BASE_FONT;

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

    private void buildContent(Document document, Order order) throws Exception {
            BaseFont base = tamilBaseFont();
            Font shopFont = new Font(base, 13, Font.BOLD, Color.WHITE);
            Font headerSubFont = new Font(base, 7, Font.NORMAL, new Color(209, 250, 229));
            Font labelFont = new Font(base, 7, Font.NORMAL, MUTED_TEXT);
            Font normalFont = new Font(base, 8, Font.NORMAL, DARK_TEXT);
            Font boldFont = new Font(base, 8, Font.BOLD, DARK_TEXT);
            Font tableHeadFont = new Font(base, 7, Font.BOLD, MUTED_TEXT);
            Font saveFont = new Font(base, 8, Font.BOLD, BRAND_GREEN);
            Font totalFont = new Font(base, 13, Font.BOLD, BRAND_GREEN);
            Font footerFont = new Font(base, 7, Font.NORMAL, MUTED_TEXT);
            Font thanksFont = new Font(base, 9, Font.BOLD, BRAND_GREEN);

            // ===== Green brand header =====
            PdfPTable header = new PdfPTable(1);
            header.setWidthPercentage(100);
            PdfPCell headerCell = new PdfPCell();
            headerCell.setBackgroundColor(BRAND_GREEN);
            headerCell.setBorder(Rectangle.NO_BORDER);
            headerCell.setPaddingTop(12f);
            headerCell.setPaddingBottom(12f);
            headerCell.setPaddingLeft(12f);
            headerCell.setPaddingRight(12f);

            Paragraph shopName = new Paragraph(order.getShop().getName(), shopFont);
            shopName.setAlignment(Element.ALIGN_CENTER);
            headerCell.addElement(shopName);

            String shopLine = joinNonBlank(order.getShop().getAddressLine1(), order.getShop().getCity());
            if (!shopLine.isEmpty()) {
                Paragraph addr = new Paragraph(shopLine, headerSubFont);
                addr.setAlignment(Element.ALIGN_CENTER);
                headerCell.addElement(addr);
            }
            if (order.getShop().getOwnerPhone() != null && !order.getShop().getOwnerPhone().isBlank()) {
                Paragraph phone = new Paragraph("Ph: " + order.getShop().getOwnerPhone(), headerSubFont);
                phone.setAlignment(Element.ALIGN_CENTER);
                headerCell.addElement(phone);
            }
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
            addCell(meta, "Bill No", labelFont, Element.ALIGN_LEFT);
            addCell(meta, "Date", labelFont, Element.ALIGN_RIGHT);
            addCell(meta, "#" + order.getOrderNumber(), boldFont, Element.ALIGN_LEFT);
            addCell(meta, formatIst(order.getCreatedAt()), normalFont, Element.ALIGN_RIGHT);
            bodyCell.addElement(meta);

            String customerName = displayCustomerName(order);
            String customerPhone = order.getCustomer() != null ? order.getCustomer().getMobileNumber() : null;
            if (customerName != null || customerPhone != null) {
                bodyCell.addElement(spacer(4f));
                Paragraph custLabel = new Paragraph("Billed To", labelFont);
                bodyCell.addElement(custLabel);
                String custLine = joinNonBlank(customerName, customerPhone);
                bodyCell.addElement(new Paragraph(custLine, boldFont));
            }

            bodyCell.addElement(spacer(6f));
            bodyCell.addElement(rule());

            // ===== Items table =====
            PdfPTable table = new PdfPTable(new float[]{4f, 1.4f, 1.4f, 1f, 1.6f});
            table.setWidthPercentage(100);
            addHeadCell(table, "ITEM", tableHeadFont, Element.ALIGN_LEFT);
            addHeadCell(table, "MRP", tableHeadFont, Element.ALIGN_RIGHT);
            addHeadCell(table, "RATE", tableHeadFont, Element.ALIGN_RIGHT);
            addHeadCell(table, "QTY", tableHeadFont, Element.ALIGN_RIGHT);
            addHeadCell(table, "AMT", tableHeadFont, Element.ALIGN_RIGHT);

            BigDecimal mrpTotal = BigDecimal.ZERO;
            int totalQty = 0;
            for (OrderItem item : order.getOrderItems()) {
                BigDecimal mrp = resolveMrp(item);
                BigDecimal lineMrp = mrp.multiply(BigDecimal.valueOf(item.getQuantity()));
                mrpTotal = mrpTotal.add(lineMrp);
                totalQty += item.getQuantity();

                addCell(table, item.getProductName(), normalFont, Element.ALIGN_LEFT);
                addCell(table, stripZeros(mrp), normalFont, Element.ALIGN_RIGHT);
                addCell(table, stripZeros(item.getUnitPrice()), normalFont, Element.ALIGN_RIGHT);
                addCell(table, String.valueOf(item.getQuantity()), normalFont, Element.ALIGN_RIGHT);
                addCell(table, stripZeros(item.getTotalPrice()), boldFont, Element.ALIGN_RIGHT);
            }
            bodyCell.addElement(table);

            bodyCell.addElement(rule());
            bodyCell.addElement(spacer(4f));

            // ===== Totals =====
            PdfPTable totals = new PdfPTable(new float[]{3f, 2f});
            totals.setWidthPercentage(100);
            addCell(totals, "Items: " + order.getOrderItems().size() + " (Qty: " + totalQty + ")", normalFont, Element.ALIGN_LEFT);
            addCell(totals, "Rs. " + stripZeros(order.getSubtotal()), normalFont, Element.ALIGN_RIGHT);

            BigDecimal savings = mrpTotal.subtract(order.getSubtotal());
            if (savings.signum() > 0) {
                addCell(totals, "MRP Total", labelFont, Element.ALIGN_LEFT);
                addCell(totals, "Rs. " + stripZeros(mrpTotal), labelFont, Element.ALIGN_RIGHT);
                addCell(totals, "You Save", saveFont, Element.ALIGN_LEFT);
                addCell(totals, "Rs. " + stripZeros(savings), saveFont, Element.ALIGN_RIGHT);
            }
            if (order.getDiscountAmount() != null && order.getDiscountAmount().signum() > 0) {
                addCell(totals, "Discount", normalFont, Element.ALIGN_LEFT);
                addCell(totals, "- Rs. " + stripZeros(order.getDiscountAmount()), normalFont, Element.ALIGN_RIGHT);
            }
            if (order.getTaxAmount() != null && order.getTaxAmount().signum() > 0) {
                addCell(totals, "Tax", normalFont, Element.ALIGN_LEFT);
                addCell(totals, "Rs. " + stripZeros(order.getTaxAmount()), normalFont, Element.ALIGN_RIGHT);
            }
            bodyCell.addElement(totals);

            bodyCell.addElement(spacer(6f));

            // ===== Boxed grand total =====
            PdfPTable grand = new PdfPTable(new float[]{1f, 1f});
            grand.setWidthPercentage(100);
            PdfPCell totalLabel = new PdfPCell(new Phrase("TOTAL", totalFont));
            totalLabel.setBackgroundColor(LIGHT_GREEN);
            totalLabel.setBorder(Rectangle.NO_BORDER);
            totalLabel.setPadding(8f);
            totalLabel.setHorizontalAlignment(Element.ALIGN_LEFT);
            grand.addCell(totalLabel);
            PdfPCell totalValue = new PdfPCell(new Phrase("Rs. " + stripZeros(order.getTotalAmount()), totalFont));
            totalValue.setBackgroundColor(LIGHT_GREEN);
            totalValue.setBorder(Rectangle.NO_BORDER);
            totalValue.setPadding(8f);
            totalValue.setHorizontalAlignment(Element.ALIGN_RIGHT);
            grand.addCell(totalValue);
            bodyCell.addElement(grand);

            if (order.getPaymentMethod() != null) {
                bodyCell.addElement(spacer(4f));
                Paragraph pay = new Paragraph("Paid by: " + order.getPaymentMethod().name().replace("_", " "),
                        boldFont);
                pay.setAlignment(Element.ALIGN_CENTER);
                bodyCell.addElement(pay);
            }

            bodyCell.addElement(spacer(8f));
            Paragraph thanks = new Paragraph("Thank you for shopping with us!", thanksFont);
            thanks.setAlignment(Element.ALIGN_CENTER);
            bodyCell.addElement(thanks);

            Paragraph printed = new Paragraph("Printed: " + formatIst(order.getCreatedAt()), footerFont);
            printed.setAlignment(Element.ALIGN_CENTER);
            bodyCell.addElement(printed);

            Paragraph powered = new Paragraph("Powered by NammaOoru", footerFont);
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
}
