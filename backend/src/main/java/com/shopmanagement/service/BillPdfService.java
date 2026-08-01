package com.shopmanagement.service;

import com.lowagie.text.Document;
import com.lowagie.text.Element;
import com.lowagie.text.Font;
import com.lowagie.text.FontFactory;
import com.lowagie.text.PageSize;
import com.lowagie.text.Paragraph;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import com.shopmanagement.entity.Order;
import com.shopmanagement.entity.OrderItem;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.format.DateTimeFormatter;

/**
 * Renders a POS order/bill as a simple PDF for WhatsApp delivery.
 */
@Service
@Slf4j
public class BillPdfService {

    private static final DateTimeFormatter DATE_FORMAT = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

    public byte[] generateBillPdf(Order order) {
        Document document = new Document(PageSize.A6);
        ByteArrayOutputStream out = new ByteArrayOutputStream();

        try {
            PdfWriter.getInstance(document, out);
            document.open();

            Font titleFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 14);
            Font sectionFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 10);
            Font normalFont = FontFactory.getFont(FontFactory.HELVETICA, 9);
            Font totalFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 11);

            Paragraph shopName = new Paragraph(order.getShop().getName(), titleFont);
            shopName.setAlignment(Element.ALIGN_CENTER);
            document.add(shopName);

            if (order.getShop().getAddressLine1() != null) {
                Paragraph address = new Paragraph(order.getShop().getAddressLine1(), normalFont);
                address.setAlignment(Element.ALIGN_CENTER);
                document.add(address);
            }

            document.add(new Paragraph(" "));
            document.add(new Paragraph("Bill No: " + order.getOrderNumber(), sectionFont));
            document.add(new Paragraph("Date: " + order.getCreatedAt().format(DATE_FORMAT), normalFont));
            if (order.getCustomer() != null) {
                String customerName = order.getCustomer().getFullName();
                if (customerName != null && !customerName.trim().isEmpty()) {
                    document.add(new Paragraph("Customer: " + customerName, normalFont));
                }
                if (order.getCustomer().getMobileNumber() != null) {
                    document.add(new Paragraph("Phone: " + order.getCustomer().getMobileNumber(), normalFont));
                }
            }
            document.add(new Paragraph(" "));

            PdfPTable table = new PdfPTable(new float[]{4f, 1f, 1.5f, 1.5f});
            table.setWidthPercentage(100);

            addHeaderCell(table, "Item", sectionFont);
            addHeaderCell(table, "Qty", sectionFont);
            addHeaderCell(table, "Rate", sectionFont);
            addHeaderCell(table, "Amount", sectionFont);

            for (OrderItem item : order.getOrderItems()) {
                table.addCell(new PdfPCell(new Paragraph(item.getProductName(), normalFont)));
                table.addCell(new PdfPCell(new Paragraph(String.valueOf(item.getQuantity()), normalFont)));
                table.addCell(new PdfPCell(new Paragraph(item.getUnitPrice().toPlainString(), normalFont)));
                table.addCell(new PdfPCell(new Paragraph(item.getTotalPrice().toPlainString(), normalFont)));
            }

            document.add(table);
            document.add(new Paragraph(" "));

            document.add(new Paragraph("Subtotal: Rs. " + order.getSubtotal().toPlainString(), normalFont));
            if (order.getDiscountAmount() != null && order.getDiscountAmount().signum() > 0) {
                document.add(new Paragraph("Discount: Rs. " + order.getDiscountAmount().toPlainString(), normalFont));
            }
            if (order.getTaxAmount() != null && order.getTaxAmount().signum() > 0) {
                document.add(new Paragraph("Tax: Rs. " + order.getTaxAmount().toPlainString(), normalFont));
            }
            document.add(new Paragraph("Total: Rs. " + order.getTotalAmount().toPlainString(), totalFont));

            document.add(new Paragraph(" "));
            Paragraph thanks = new Paragraph("Thank you for shopping with us!", normalFont);
            thanks.setAlignment(Element.ALIGN_CENTER);
            document.add(thanks);

        } catch (Exception e) {
            log.error("Failed to generate bill PDF for order {}", order.getOrderNumber(), e);
            throw new RuntimeException("Failed to generate bill PDF", e);
        } finally {
            document.close();
        }

        return out.toByteArray();
    }

    private void addHeaderCell(PdfPTable table, String text, Font font) {
        PdfPCell cell = new PdfPCell(new Paragraph(text, font));
        table.addCell(cell);
    }
}
