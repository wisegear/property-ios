import Foundation

struct EPCCertificateDetailResponse: Decodable, Equatable {
    let data: EPCCertificateDetail
}

struct EPCCertificateDetail: Decodable, Equatable {
    let reference: String?
    let reportReferenceNumber: String?
    let lmkKey: String?
    let buildingReferenceNumber: String?
    let uprn: String?
    let address: EPCAddress?
    let certificate: EPCCertificateIdentity?
    let property: EPCPropertyCharacteristics?
    let energy: EPCEnergyPerformance?
    let environmentalImpact: EPCEnvironmentalImpact?
    let estimatedCosts: EPCEstimatedCosts?
    let construction: EPCConstruction?
    let heating: EPCHeating?
    let lighting: EPCLighting?
    let renewables: EPCRenewables?
    let recommendations: [JSONValue]?
    let websiteURL: String?

    enum CodingKeys: String, CodingKey {
        case reference
        case reportReferenceNumber = "report_reference_number"
        case lmkKey = "lmk_key"
        case buildingReferenceNumber = "building_reference_number"
        case uprn
        case address
        case certificate
        case property
        case energy
        case environmentalImpact = "environmental_impact"
        case estimatedCosts = "estimated_costs"
        case construction
        case heating
        case lighting
        case renewables
        case recommendations
        case websiteURL = "website_url"
    }
}

struct EPCAddress: Decodable, Equatable {
    let display: String?
    let line1: String?
    let line2: String?
    let line3: String?
    let postTown: String?
    let postcode: String?
    let localAuthority: String?
    let county: String?
    let region: String?
    let country: String?

    enum CodingKeys: String, CodingKey {
        case display
        case line1 = "line_1"
        case line2 = "line_2"
        case line3 = "line_3"
        case postTown = "post_town"
        case postcode
        case localAuthority = "local_authority"
        case county
        case region
        case country
    }
}

struct EPCCertificateIdentity: Decodable, Equatable {
    let inspectionDate: String?
    let lodgementDate: String?
    let lodgementDatetime: String?
    let transactionType: String?
    let reportType: String?

    enum CodingKeys: String, CodingKey {
        case inspectionDate = "inspection_date"
        case lodgementDate = "lodgement_date"
        case lodgementDatetime = "lodgement_datetime"
        case transactionType = "transaction_type"
        case reportType = "report_type"
    }
}

struct EPCPropertyCharacteristics: Decodable, Equatable {
    let type: String?
    let builtForm: String?
    let constructionAgeBand: String?
    let tenure: String?
    let totalFloorAreaSquareMetres: Double?
    let floorLevel: String?
    let floorHeight: Double?
    let flatTopStorey: String?
    let flatStoreyCount: Int?
    let habitableRooms: Int?
    let heatedRooms: Int?
    let extensions: Int?
    let openFireplaces: Int?

    enum CodingKeys: String, CodingKey {
        case type
        case builtForm = "built_form"
        case constructionAgeBand = "construction_age_band"
        case tenure
        case totalFloorAreaSquareMetres = "total_floor_area_square_metres"
        case floorLevel = "floor_level"
        case floorHeight = "floor_height"
        case flatTopStorey = "flat_top_storey"
        case flatStoreyCount = "flat_storey_count"
        case habitableRooms = "habitable_rooms"
        case heatedRooms = "heated_rooms"
        case extensions
        case openFireplaces = "open_fireplaces"
    }
}

struct EPCEnergyPerformance: Decodable, Equatable {
    let currentRating: String?
    let potentialRating: String?
    let currentEfficiency: Int?
    let potentialEfficiency: Int?
    let currentConsumptionKWhPerSquareMetre: Double?
    let potentialConsumptionKWhPerSquareMetre: Double?
    let tariff: String?

    enum CodingKeys: String, CodingKey {
        case currentRating = "current_rating"
        case potentialRating = "potential_rating"
        case currentEfficiency = "current_efficiency"
        case potentialEfficiency = "potential_efficiency"
        case currentConsumptionKWhPerSquareMetre = "current_consumption_kwh_per_square_metre"
        case potentialConsumptionKWhPerSquareMetre = "potential_consumption_kwh_per_square_metre"
        case tariff
    }
}

struct EPCEnvironmentalImpact: Decodable, Equatable {
    let currentScore: Int?
    let potentialScore: Int?
    let currentCO2EmissionsTonnes: Double?
    let potentialCO2EmissionsTonnes: Double?
    let currentCO2PerSquareMetre: Double?

    enum CodingKeys: String, CodingKey {
        case currentScore = "current_score"
        case potentialScore = "potential_score"
        case currentCO2EmissionsTonnes = "current_co2_emissions_tonnes"
        case potentialCO2EmissionsTonnes = "potential_co2_emissions_tonnes"
        case currentCO2PerSquareMetre = "current_co2_per_square_metre"
    }
}

struct EPCEstimatedCosts: Decodable, Equatable {
    let lighting: EPCCostPair?
    let heating: EPCCostPair?
    let hotWater: EPCCostPair?

    enum CodingKeys: String, CodingKey {
        case lighting
        case heating
        case hotWater = "hot_water"
    }
}

struct EPCCostPair: Decodable, Equatable {
    let current: Double?
    let potential: Double?
}

struct EPCConstruction: Decodable, Equatable {
    let walls: EPCComponent?
    let roof: EPCComponent?
    let floor: EPCComponent?
    let windows: EPCComponent?
    let glazedType: String?
    let glazedArea: String?
    let multiGlazeProportion: Double?

    enum CodingKeys: String, CodingKey {
        case walls
        case roof
        case floor
        case windows
        case glazedType = "glazed_type"
        case glazedArea = "glazed_area"
        case multiGlazeProportion = "multi_glaze_proportion"
    }
}

struct EPCComponent: Decodable, Equatable {
    let description: String?
    let energyEfficiency: String?
    let environmentalEfficiency: String?

    enum CodingKeys: String, CodingKey {
        case description
        case energyEfficiency = "energy_efficiency"
        case environmentalEfficiency = "environmental_efficiency"
    }
}

struct EPCHeating: Decodable, Equatable {
    let main: EPCComponent?
    let mainControls: EPCComponent?
    let secondary: EPCComponent?
    let hotWater: EPCComponent?
    let mainFuel: String?
    let mainsGas: String?
    let mechanicalVentilation: String?

    enum CodingKeys: String, CodingKey {
        case main
        case mainControls = "main_controls"
        case secondary
        case hotWater = "hot_water"
        case mainFuel = "main_fuel"
        case mainsGas = "mains_gas"
        case mechanicalVentilation = "mechanical_ventilation"
    }
}

struct EPCLighting: Decodable, Equatable {
    let description: String?
    let energyEfficiency: String?
    let environmentalEfficiency: String?
    let lowEnergyPercentage: Double?
    let fixedOutlets: Int?
    let lowEnergyFixedOutlets: Int?

    enum CodingKeys: String, CodingKey {
        case description
        case energyEfficiency = "energy_efficiency"
        case environmentalEfficiency = "environmental_efficiency"
        case lowEnergyPercentage = "low_energy_percentage"
        case fixedOutlets = "fixed_outlets"
        case lowEnergyFixedOutlets = "low_energy_fixed_outlets"
    }
}

struct EPCRenewables: Decodable, Equatable {
    let photoSupply: String?
    let solarWaterHeating: String?
    let windTurbines: Int?

    enum CodingKeys: String, CodingKey {
        case photoSupply = "photo_supply"
        case solarWaterHeating = "solar_water_heating"
        case windTurbines = "wind_turbines"
    }
}
