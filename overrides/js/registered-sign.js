function wrapRegisteredSign() {
    const registeredSign = "®";
    const registeredSignClass = "registered-sign";
    const textNodes = document.evaluate(
        "//*/text()",
        document,
        null,
        XPathResult.UNORDERED_NODE_SNAPSHOT_TYPE,
        null
    );

    for (let i = 0; i < textNodes.snapshotLength; ++i) {
        const textNode = textNodes.snapshotItem(i);
        const parent = textNode.parentElement;

        let registeredSignPos = textNode.textContent.indexOf(registeredSign);
        if (
            registeredSignPos === 0
            && parent.tagName.toLowerCase() === "span"
            && parent.getAttribute("class") === registeredSignClass
        ) {
            continue;
        }

        let registeredSignPositions = [];
        while (registeredSignPos !== -1) {
            registeredSignPositions.push(registeredSignPos);

            registeredSignPos = textNode.textContent.indexOf(registeredSign, registeredSignPos + 1);
        }
        if (!registeredSignPositions.length) {
            continue;
        }

        const newContent = document.createDocumentFragment();
        let start = 0;
        registeredSignPositions.forEach(function (position) {
            const spanNode = document.createElement("span");
            spanNode.setAttribute("class", registeredSignClass);
            spanNode.appendChild(document.createTextNode(registeredSign));

            newContent.appendChild(document.createTextNode(textNode.textContent.substring(start, position)));
            newContent.appendChild(spanNode);

            start = position + 1;
        })
      
        newContent.appendChild(document.createTextNode(textNode.textContent.substring(start)));

        parent.replaceChild(newContent, textNode);
    }
}

document.addEventListener("DOMContentLoaded", wrapRegisteredSign);
