// Runs in Safari's already-loaded page when the user shares it.
function weeklyAmounts(text) {
    var pattern = /\$\s*([0-9]{1,5}(?:,[0-9]{3})?(?:\.[0-9]{2})?)\s*(?:\/\s*(?:week|wk)\b|per\s+week\b|p\.?\s*w\.?\b|a\s+week\b)/gi;
    var values = [], match;
    while ((match = pattern.exec(text || "")) !== null) {
        var value = Number(match[1].replace(/,/g, ""));
        if (value > 0 && values.indexOf(value) < 0) values.push(value);
    }
    return values;
}
function listingWeeklyRent(doc) {
    // Prefer listing-specific price elements over recommendation cards.
    var selectors = ['[data-testid="property-price"]', '.property-price', '[data-testid="listing-details__summary-title"]'];
    for (var i = 0; i < selectors.length; i++) {
        var nodes = doc.querySelectorAll(selectors[i]);
        var amounts = [];
        for (var j = 0; j < nodes.length; j++) {
            weeklyAmounts(nodes[j].innerText || nodes[j].textContent).forEach(function (n) { if (amounts.indexOf(n) < 0) amounts.push(n); });
        }
        if (amounts.length === 1) return amounts[0];
    }
    // The visible primary listing, stopping before neighbouring recommendations.
    var main = doc.querySelector('main') || doc.body;
    var text = (main && main.innerText || '').split(/similar properties|recommended properties|you may also like|other properties you might like/i)[0];
    var prices = weeklyAmounts(text);
    return prices.length === 1 ? prices[0] : null;
}
var ExtensionPreprocessingJS = {
    run: function (args) {
        var result = { url: document.URL, title: document.title };
        var price = listingWeeklyRent(document);
        if (price !== null) result.weeklyRent = price;
        args.completionFunction(result);
    }
};
