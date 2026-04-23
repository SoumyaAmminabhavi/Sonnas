import fs from 'fs';
import PDFParser from 'pdf2json';

let pdfParser = new PDFParser(this, 1);

pdfParser.on("pdfParser_dataError", errData => console.error(errData.parserError) );
pdfParser.on("pdfParser_dataReady", pdfData => {
    fs.writeFileSync("Menu.txt", pdfParser.getRawTextContent());
    console.log("Written to Menu.txt");
});

pdfParser.loadPDF("Menu.pdf");
