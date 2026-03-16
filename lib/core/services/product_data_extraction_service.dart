import 'package:google_mlkit_entity_extraction/google_mlkit_entity_extraction.dart';
import 'package:kkpchatapp/core/services/logging_service.dart';

class ProductDataExtractionService {
  late final EntityExtractor _entityExtractor;
  final LoggingService _logger = LoggingService.instance;

  ProductDataExtractionService() {
    _entityExtractor = EntityExtractor(language: EntityExtractorLanguage.english);
  }

  /// Initialize the entity extractor
  Future<void> initialize() async {
    // Entity extractor is initialized in constructor
  }

  /// Extract product data from a text message
  Future<Map<String, dynamic>?> extractProductData(String message) async {
    final startTime = DateTime.now();
    Map<String, dynamic> extractedData = {};

    try {
      // Use ML Kit to extract entities
      final List<EntityAnnotation> annotations = await _entityExtractor.annotateText(message);

      // Process ML Kit entities
      for (final annotation in annotations) {
        for (final entity in annotation.entities) {
          switch (entity.type) {
            case EntityType.money:
              extractedData['rate'] = _parseMoney(entity.rawValue);
              break;
            case EntityType.dateTime:
              // Could be used for delivery dates, etc.
              extractedData['date'] = entity.rawValue;
              break;
            default:
              // Handle unknown entity types or ignore them
              break;
          }
        }
      }
    } catch (e) {
      // ML Kit not available (e.g., in tests), continue with regex extraction
      _logger.logStorage('ML Kit extraction failed, using regex only: $e', level: LogLevel.warning);
    }

    // Use regex for custom fields that ML Kit doesn't handle
    extractedData.addAll(_extractCustomFields(message));

    // Calculate extraction time
    final endTime = DateTime.now();
    final extractionTimeMs = endTime.difference(startTime).inMilliseconds;
    extractedData['extractionTimeMs'] = extractionTimeMs;

    // Only return if we have meaningful data
    if (extractedData.isNotEmpty && _hasRequiredFields(extractedData)) {
      extractedData['confidence'] = _calculateConfidence(extractedData);
      return extractedData;
    }

    return null;
  }

  /// Extract custom fields using regex patterns
  Map<String, dynamic> _extractCustomFields(String message) {
    Map<String, dynamic> customData = {};

    // Quantity extraction from explicit quantity and unit phrases first
    final quantityUnitRegex = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:meters?|metres?|m|kg|kgs?|grams?|g|pieces?|pcs?|yards?|yds?|feet?|ft|rolls?|bundles?|sets?|liters?|litres?|l|yards?|yd|meter|metre|units?|items?)\b',
      caseSensitive: false,
    );
    final quantityUnitMatch = quantityUnitRegex.firstMatch(message);
    if (quantityUnitMatch != null) {
      customData['quantity'] = num.tryParse(quantityUnitMatch.group(1)!);
    }

    // If quantity not found, look for direct requests with numbers
    if (customData['quantity'] == null) {
      final requestQuantityRegex = RegExp(
        r'(?:need|want|require|looking\s*for|order|buy|purchase|quantity|qty|amount)\s*(?:of\s*)?(\d+(?:\.\d+)?)',
        caseSensitive: false,
      );
      final requestQuantityMatch = requestQuantityRegex.firstMatch(message);
      if (requestQuantityMatch != null) {
        customData['quantity'] = num.tryParse(requestQuantityMatch.group(1)!);
      }
    }

    // Enhanced quality patterns with more phrases and keywords
    final qualityRegex = RegExp(
        r'(?:quality|grade|class|type|standard|level|rating)\s*(?:of|is|should\s*be|required|wanted|needed)\s*[:\-]?\s*([a-zA-Z0-9\s]+)',
        caseSensitive: false);
    final qualityMatch = qualityRegex.firstMatch(message);
    if (qualityMatch != null) {
      customData['quality'] = qualityMatch.group(1)?.trim();
    }

    // Alternative quality patterns with extensive terms and misspellings
    if (customData['quality'] == null) {
      final altQualityRegex = RegExp(
          r'\b(premium|premimum|premeum|premiumm|standard|standrd|stndrd|stndard|high|hgh|hi|low|lw|lo|good|gd|gd|poor|pr|pr|excellent|excllent|exellent|exclent|superior|suprior|supirior|suprior|basic|bsc|bsc|deluxe|dluxe|dlux|luxury|luxry|luxary|luxry|economy|ecoomy|ecnomy|ecny|fine|fn|fn|coarse|crs|crs|medium|med|med|average|avg|avrg|top|tp|tp|best|bst|bst|cheap|chp|chp|expensive|expnsive|expnsv|expns|first\s*class|1st\s*class|second\s*grade|2nd\s*grade|third\s*rate|3rd\s*rate|super|spr|ultra|ultr|elite|elt|budget|bdgt|value|vl|affordable|afordable|affordble|durable|durble|durb|long\s*lasting|longlast|reliable|relible|relbl|trustworthy|trustwrthy|high\s*end|hghend|low\s*end|lowend|mid\s*range|midrange|entry\s*level|entrylevel|professional|profesional|prof|industrial|industrl|indstrl|commercial|commercl|comrcial|domestic|dmstc|household|hshld)\b',
          caseSensitive: false);
      final altQualityMatch = altQualityRegex.firstMatch(message);
      if (altQualityMatch != null) {
        customData['quality'] = altQualityMatch.group(1);
      }
    }

    // Weave patterns: prefer phrases like 'twill weave' and then fallback to patterns
    final weaveBeforeRegex = RegExp(r'([a-zA-Z]+)\s+weave\b', caseSensitive: false);
    final weaveBeforeMatch = weaveBeforeRegex.firstMatch(message);
    if (weaveBeforeMatch != null) {
      customData['weave'] = weaveBeforeMatch.group(1)?.trim();
    }

    if (customData['weave'] == null) {
      final weaveRegex = RegExp(
        r'\b(?:weave|texture|pattern|finish|structure|design)\b\s*(?:of|is|should\s*be|required|wanted|needed)?\s*[:\-]?\s*([a-zA-Z]+)',
        caseSensitive: false,
      );
      final weaveMatch = weaveRegex.firstMatch(message);
      if (weaveMatch != null) {
        customData['weave'] = weaveMatch.group(1)?.trim();
      }
    }

    if (customData['weave'] == null) {
      final altWeaveRegex = RegExp(
        r'\b(plain|twill|satin|jacquard|knit|woven|ribbed|corduroy|velvet|chiffon|crepe|denim|canvas|linen|silk|wool|nylon|rayon|spandex|acrylic|viscose)\b',
        caseSensitive: false,
      );
      final altWeaveMatch = altWeaveRegex.firstMatch(message);
      if (altWeaveMatch != null) {
        customData['weave'] = altWeaveMatch.group(1);
      }
    }

    // Composition patterns with robust extraction and cleanup
    final compositionRegex = RegExp(
      r'composition\s*[:\-]?\s*([^,\.]+)',
      caseSensitive: false,
    );
    final compositionMatch = compositionRegex.firstMatch(message);
    if (compositionMatch != null) {
      final composition = compositionMatch.group(1)?.trim();
      if (composition != null && composition.isNotEmpty) {
        customData['composition'] =
            composition.replaceAll(RegExp(r'price.*', caseSensitive: false), '').trim();
      }
    }

    if (customData['composition'] == null) {
      final fabricRegex = RegExp(
        r'\b([a-zA-Z]+)\s+(?:fabric|cloth|material)\b',
        caseSensitive: false,
      );
      final fabricMatch = fabricRegex.firstMatch(message);
      if (fabricMatch != null) {
        final maybeMaterial = fabricMatch.group(1)?.trim();
        if (maybeMaterial != null &&
            !RegExp(r'^(need|want|give|looking|require|buy|purchase)$', caseSensitive: false)
                .hasMatch(maybeMaterial)) {
          customData['composition'] = '$maybeMaterial fabric';
        }
      }
    }

    if (customData['composition'] == null) {
      final materialRegex = RegExp(
        r'\b(cotton|polyester|silk|wool|linen|nylon|rayon|viscose|spandex|acrylic|denim|canvas|leather|lace|velvet|chiffon|crepe|jacquard|brocade|corduroy)\b',
        caseSensitive: false,
      );
      final materialMatch = materialRegex.firstMatch(message);
      if (materialMatch != null) {
        customData['composition'] = materialMatch.group(1);
      }
    }

    // Price patterns (per unit) with more phrases and variations
    if (!customData.containsKey('rate')) {
      final priceRegex = RegExp(
          r'(?:price|rate|cost|amount|value|charge|fee|pricing|quotation|quote|budget|expense|spending|outlay|expenditure|payment|pay|bill|invoice|tariff|fare|levy|tax|duty)\s*(?:should\s*(?:not\s*)?be|is|of|at|for|around|about|nearly|close\s*to|up\s*to|down\s*to|maximum|max|minimum|min|expected|wanted|needed|required|demanded|asked|offered|quoted|listed|marked|set|fixed|agreed|negotiated|final|total|net|gross|inclusive|exclusive)\s*(?:more\s*than|less\s*than|around|about|nearly|close\s*to|up\s*to|down\s*to|between|from|starting\s*at|as\s*low\s*as|as\s*high\s*as)?\s*(?:Rs\.?|INR|rupees?|bucks?|dollars?|USD|\$|€|EUR|euros?|£|GBP|pounds?|¥|JPY|yen|₽|RUB|rubles?|₹|inr)\s*(\d+(?:\.\d+)?)\s*(?:per\s*(?:meter|m|metre|kg|kgs?|piece|pc|pcs?|yard|yd|yds?|feet?|ft|roll|bundle|set|liter|l|litre|gal|ton|t|box|carton|pack|dozen|dz|spool|reel|bale|sheet|panel|tile|block|unit|item)|\/?\s*(?:meter|m|metre|kg|kgs?|piece|pc|pcs?|yard|yd|yds?|feet?|ft|roll|bundle|set|liter|l|litre|gal|ton|t|box|carton|pack|dozen|dz|spool|reel|bale|sheet|panel|tile|block|unit|item))',
          caseSensitive: false);
      final priceMatch = priceRegex.firstMatch(message);
      if (priceMatch != null) {
        customData['rate'] = num.tryParse(priceMatch.group(1)!);
      }
    }

    // Additional extraction for buyer/customer name
    final buyerNameRegex = RegExp(
      r'\b(?:buyer|customer|client|sender)\s*(?:name)?\s*(?:is|:|=|-)\s*([A-Z][a-zA-Z ]{1,50})\b',
      caseSensitive: false,
    );
    final buyerNameMatch = buyerNameRegex.firstMatch(message);
    if (buyerNameMatch != null) {
      customData['customerName'] = buyerNameMatch.group(1)?.trim();
    }

    if (customData['customerName'] == null) {
      final nameFromToRegex = RegExp(
        r'\b(?:to|for)\s*([A-Z][a-zA-Z ]{1,50})\b',
        caseSensitive: false,
      );
      final nameFromToMatch = nameFromToRegex.firstMatch(message);
      if (nameFromToMatch != null) {
        final candidate = nameFromToMatch.group(1)?.trim();
        if (candidate != null && candidate.split(' ').length <= 3) {
          customData['customerName'] = candidate;
        }
      }
    }

    // Additional patterns for product type or category with more phrases
    final productTypeRegex = RegExp(
        r'(?:product|item|type|category|kind|sort|variety|class|genre|species|brand|model|style|design|pattern|version|edition|series|line|range|collection|family|group|set|kit|package|bundle|assortment)\s*(?:of|is|should\s*be|required|wanted|needed|looking\s*for|searching\s*for|interested\s*in)\s*[:\-]?\s*(\w+)',
        caseSensitive: false);
    final productTypeMatch = productTypeRegex.firstMatch(message);
    if (productTypeMatch != null) {
      customData['productType'] = productTypeMatch.group(1);
    }

    // Color patterns with more phrases
    final colorRegex = RegExp(
        r'(?:color|colour|hue|shade|tint|tone|pigment|dye|paint|finish|coating)\s*(?:of|is|should\s*be|required|wanted|needed|preferred|liked|desired)\s*[:\-]?\s*(\w+)',
        caseSensitive: false);
    final colorMatch = colorRegex.firstMatch(message);
    if (colorMatch != null) {
      customData['color'] = colorMatch.group(1);
    }

    // Size patterns with more phrases
    final sizeRegex = RegExp(
        r'(?:size|dimension|measurement|scale|proportion|extent|scope|range|capacity|volume|area|length|width|height|depth|thickness|gauge|caliber|bore)\s*(?:of|is|should\s*be|required|wanted|needed)\s*[:\-]?\s*([\w\s]+)',
        caseSensitive: false);
    final sizeMatch = sizeRegex.firstMatch(message);
    if (sizeMatch != null) {
      customData['size'] = sizeMatch.group(1)?.trim();
    }

    // Brand or supplier patterns with more phrases
    final brandRegex = RegExp(
        r'(?:brand|supplier|manufacturer|company|maker|producer|vendor|seller|retailer|distributor|provider|source|origin|label|mark|trademark|logo)\s*(?:of|is|should\s*be|required|wanted|needed|preferred|trusted|reliable|recommended)\s*[:\-]?\s*(\w+)',
        caseSensitive: false);
    final brandMatch = brandRegex.firstMatch(message);
    if (brandMatch != null) {
      customData['brand'] = brandMatch.group(1);
    }

    // Delivery or shipping patterns
    final deliveryRegex = RegExp(
        r'(?:delivery|shipping|transport|dispatch|send|ship|deliver|supply|provide|supply|forward|mail|post|courier|freight|haulage|carriage)\s*(?:time|period|schedule|date|deadline|ETA|expected|within|by|before|after)\s*[:\-]?\s*([\w\s]+)',
        caseSensitive: false);
    final deliveryMatch = deliveryRegex.firstMatch(message);
    if (deliveryMatch != null) {
      customData['delivery'] = deliveryMatch.group(1)?.trim();
    }

    // Payment terms patterns
    final paymentRegex = RegExp(
        r'(?:payment|pay|settlement|remittance|transfer|deposit|advance|installment|credit|cash|cheque|check|wire|bank|online|card|debit|credit|net|terms|condition)\s*(?:terms|method|mode|way|option|plan|schedule)\s*[:\-]?\s*([\w\s]+)',
        caseSensitive: false);
    final paymentMatch = paymentRegex.firstMatch(message);
    if (paymentMatch != null) {
      customData['paymentTerms'] = paymentMatch.group(1)?.trim();
    }

    // Origin or source patterns
    final originRegex = RegExp(
        r'(?:origin|source|from|made\s*in|produced\s*in|manufactured\s*in|imported\s*from|exported\s*from|country|place|location|region|area|zone|territory)\s*[:\-]?\s*(\w+)',
        caseSensitive: false);
    final originMatch = originRegex.firstMatch(message);
    if (originMatch != null) {
      customData['origin'] = originMatch.group(1);
    }

    return customData;
  }

  /// Parse money values from ML Kit entities
  num? _parseMoney(String rawValue) {
    // Remove currency symbols and parse
    final cleanValue = rawValue.replaceAll(RegExp(r'[^\d.]'), '');
    return num.tryParse(cleanValue);
  }

  /// Check if extracted data has required fields for a valid product entry
  bool _hasRequiredFields(Map<String, dynamic> data) {
    // At least one meaningful field should be present
    return data.containsKey('quality') ||
        data.containsKey('weave') ||
        data.containsKey('quantity') ||
        data.containsKey('composition') ||
        data.containsKey('rate');
  }

  /// Calculate confidence score based on number of fields extracted
  double _calculateConfidence(Map<String, dynamic> data) {
    int fieldCount = data.keys.where((key) => key != 'confidence').length;
    // Simple confidence based on field count (max 5 fields)
    return (fieldCount / 5.0).clamp(0.0, 1.0);
  }

  /// Clean up resources
  void dispose() {
    _entityExtractor.close();
  }
}
