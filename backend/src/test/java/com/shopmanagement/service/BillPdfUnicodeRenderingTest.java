package com.shopmanagement.service;

import com.lowagie.text.Document;
import com.lowagie.text.Font;
import com.lowagie.text.FontFactory;
import com.lowagie.text.Rectangle;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.rendering.ImageType;
import org.apache.pdfbox.rendering.PDFRenderer;
import org.junit.jupiter.api.Test;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.lang.reflect.Method;
import java.nio.file.Files;
import java.nio.file.Path;
import java.text.Normalizer;

import static org.junit.jupiter.api.Assertions.assertTrue;

class BillPdfUnicodeRenderingTest {
    @Test
    void shapesNormalizedMixedLanguageNamesThroughPdfToImagePipeline() throws Exception {
        BillPdfService service = new BillPdfService(null);
        Method renderName = BillPdfService.class.getDeclaredMethod(
                "addItemNameCell", PdfPTable.class, String.class,
                Font.class, Font.class, float.class);
        renderName.setAccessible(true);

        ByteArrayOutputStream pdf = new ByteArrayOutputStream();
        Document document = new Document(new Rectangle(420, 300));
        PdfWriter.getInstance(document, pdf);
        document.open();
        PdfPTable table = new PdfPTable(1);
        table.setWidthPercentage(100);
        Font font = FontFactory.getFont(FontFactory.HELVETICA, 16);
        for (String name : new String[] {
                "Rice (தமிழ் மொழி) 1kg",
                "दाल Hindi 1kg",
                "أرز Arabic 1kg"
        }) {
            renderName.invoke(service, table,
                    Normalizer.normalize(name, Normalizer.Form.NFD),
                    font, font, 370f);
        }
        document.add(table);
        document.close();

        BufferedImage image;
        try (PDDocument renderedPdf = PDDocument.load(pdf.toByteArray())) {
            image = new PDFRenderer(renderedPdf).renderImageWithDPI(0, 300, ImageType.RGB);
        }
        Path output = Path.of("target", "unicode-receipt-render.png");
        ImageIO.write(image, "PNG", output.toFile());
        assertTrue(Files.size(output) > 10_000, "Rendered receipt image should contain visible text");
    }
}
