package com.shopmanagement.service;

import com.lowagie.text.Document;
import com.lowagie.text.Element;
import com.lowagie.text.Font;
import com.lowagie.text.FontFactory;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Rectangle;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import com.shopmanagement.entity.Order;
import com.shopmanagement.entity.OrderItem;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.math.BigDecimal;
import java.time.format.DateTimeFormatter;

/**
 * Renders a POS order as a PDF matching the printed thermal receipt style:
 * shop header, dashed separators, ITEM/MRP/RATE/QTY/AMT columns,
 * MRP total + savings, payment method and thank-you footer.
 */
@Service
@Slf4j
public class BillPdfService {

    private static final DateTimeFormatter DATE_FORMAT = DateTimeFormatter.ofPattern("dd/MM/yyyy hh:mm a");
    private static final String DASHES = "--------------------------------------------";

    public byte[] generateBillPdf(Order order) {
        // Narrow page like a receipt (80mm wide roll)
        Rectangle pageSize = new Rectangle(227f, 570f);
        Document document = new Document(pageSize, 12f, 12f, 14f, 14f);
        ByteArrayOutputStream out = new ByteArrayOutputStream();

        try {
            PdfWriter.getInstance(document, out);
            document.open();

            Font shopFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 13);
            Font subFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 9);
            Font normalFont = FontFactory.getFont(FontFactory.HELVETICA, 8);
            Font boldFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 8);
            Font totalFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 12);
            Font dashFont = FontFactory.getFont(FontFactory.HELVETICA, 7);

            addCentered(document, order.getShop().getName(), shopFont);
            addCentered(document, "Order Receipt", subFont);
            addCentered(document, DASHES, dashFont);

            addCentered(document, "#" + order.getOrderNumber() + " | " + order.getCreatedAt().format(DATE_FORMAT), boldFont);
            addCentered(document, DASHES, dashFont);

            if (order.getCustomer() != null) {
                String customerName = order.getCustomer().getFullName();
                if (customerName != null && !customerName.trim().isEmpty()) {
                    document.add(new Paragraph(customerName, boldFont));
                }
                if (order.getCustomer().getMobileNumber() != null) {
                    document.add(new Paragraph(order.getCustomer().getMobileNumber(), normalFont));
                }
                addCentered(document, DASHES, dashFont);
            }

            // ITEM | MRP | RATE | QTY | AMT
            PdfPTable table = new PdfPTable(new float[]{4f, 1.4f, 1.4f, 1f, 1.6f});
            table.setWidthPercentage(100);
            addCell(table, "ITEM", boldFont, Element.ALIGN_LEFT);
            addCell(table, "MRP", boldFont, Element.ALIGN_RIGHT);
            addCell(table, "RATE", boldFont, Element.ALIGN_RIGHT);
            addCell(table, "QTY", boldFont, Element.ALIGN_RIGHT);
            addCell(table, "AMT", boldFont, Element.ALIGN_RIGHT);

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
                addCell(table, stripZeros(item.getTotalPrice()), normalFont, Element.ALIGN_RIGHT);
            }
            document.add(table);

            addCentered(document, DASHES, dashFont);

            PdfPTable totals = new PdfPTable(new float[]{3f, 2f});
            totals.setWidthPercentage(100);
            addCell(totals, "Items: " + order.getOrderItems().size() + " (Qty: " + totalQty + ")", boldFont, Element.ALIGN_LEFT);
            addCell(totals, "Rs. " + stripZeros(order.getSubtotal()), boldFont, Element.ALIGN_RIGHT);

            BigDecimal savings = mrpTotal.subtract(order.getSubtotal());
            if (savings.signum() > 0) {
                addCell(totals, "MRP Total", normalFont, Element.ALIGN_LEFT);
                addCell(totals, "Rs. " + stripZeros(mrpTotal), normalFont, Element.ALIGN_RIGHT);
                addCell(totals, "You Save", normalFont, Element.ALIGN_LEFT);
                addCell(totals, "Rs. " + stripZeros(savings), normalFont, Element.ALIGN_RIGHT);
            }
            if (order.getDiscountAmount() != null && order.getDiscountAmount().signum() > 0) {
                addCell(totals, "Discount", normalFont, Element.ALIGN_LEFT);
                addCell(totals, "- Rs. " + stripZeros(order.getDiscountAmount()), normalFont, Element.ALIGN_RIGHT);
            }
            if (order.getTaxAmount() != null && order.getTaxAmount().signum() > 0) {
                addCell(totals, "Tax", normalFont, Element.ALIGN_LEFT);
                addCell(totals, "Rs. " + stripZeros(order.getTaxAmount()), normalFont, Element.ALIGN_RIGHT);
            }
            document.add(totals);

            addCentered(document, DASHES, dashFont);

            PdfPTable grand = new PdfPTable(new float[]{1f, 1f});
            grand.setWidthPercentage(100);
            addCell(grand, "TOTAL", totalFont, Element.ALIGN_LEFT);
            addCell(grand, "Rs. " + stripZeros(order.getTotalAmount()), totalFont, Element.ALIGN_RIGHT);
            document.add(grand);

            addCentered(document, DASHES, dashFont);

            if (order.getPaymentMethod() != null) {
                addCentered(document, order.getPaymentMethod().name().replace("_", " "), boldFont);
                addCentered(document, DASHES, dashFont);
            }

            addCentered(document, "Thank you for your order!", boldFont);
            addCentered(document, "Printed: " + order.getCreatedAt().format(DATE_FORMAT), normalFont);

        } catch (Exception e) {
            log.error("Failed to generate bill PDF for order {}", order.getOrderNumber(), e);
            throw new RuntimeException("Failed to generate bill PDF", e);
        } finally {
            document.close();
        }

        return out.toByteArray();
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

    private void addCentered(Document document, String text, Font font) {
        Paragraph p = new Paragraph(text, font);
        p.setAlignment(Element.ALIGN_CENTER);
        document.add(p);
    }

    private void addCell(PdfPTable table, String text, Font font, int align) {
        PdfPCell cell = new PdfPCell(new Paragraph(text, font));
        cell.setBorder(Rectangle.NO_BORDER);
        cell.setHorizontalAlignment(align);
        cell.setPaddingTop(2f);
        cell.setPaddingBottom(2f);
        table.addCell(cell);
    }
}
