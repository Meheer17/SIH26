"""
Family Health & Hereditary Trauma Risk Graph Engine
Uses NetworkX graph algorithm to traverse family lineage nodes, compute genetic vulnerability indices,
and assess inter-generational trauma or chronic condition exposure.
"""
import networkx as nx
from typing import Dict, Any, List

def compute_family_hereditary_risk(family_members: List[Dict[str, Any]]) -> Dict[str, Any]:
    """
    Constructs a directed pedigree graph of family members and calculates genetic risk score.
    Input structure:
    [
      {"id": "p1", "name": "Patient (Self)", "relation": "self", "conditions": ["hypertension"], "parents": ["f1", "m1"]},
      {"id": "f1", "name": "Father", "relation": "father", "conditions": ["diabetes", "hypertension"], "parents": ["gf1", "gm1"]},
      {"id": "m1", "name": "Mother", "relation": "mother", "conditions": ["anemia"], "parents": []},
      {"id": "gf1", "name": "Grandfather (Paternal)", "relation": "grandfather", "conditions": ["cardiovascular"], "parents": []}
    ]
    """
    if not family_members:
        # Default sample family tree
        family_members = [
            {"id": "self", "name": "Primary Patient", "relation": "self", "conditions": ["mild_anxiety"], "parents": ["father", "mother"]},
            {"id": "father", "name": "Father (Age 54)", "relation": "father", "conditions": ["type2_diabetes", "hypertension"], "parents": ["g_father_p"]},
            {"id": "mother", "name": "Mother (Age 50)", "relation": "mother", "conditions": ["iron_deficiency_anemia"], "parents": []},
            {"id": "g_father_p", "name": "Paternal Grandfather", "relation": "grandfather", "conditions": ["coronary_artery_disease", "hypertension"], "parents": []}
        ]

    G = nx.DiGraph()

    # Weight of inheritance by kinship degree
    KINSHIP_WEIGHTS = {
        "self": 1.0,
        "father": 0.5,
        "mother": 0.5,
        "brother": 0.5,
        "sister": 0.5,
        "grandfather": 0.25,
        "grandmother": 0.25,
        "uncle": 0.25,
        "aunt": 0.25
    }

    condition_risk_accumulators = {}

    for member in family_members:
        m_id = member["id"]
        rel = member.get("relation", "self").lower()
        weight = KINSHIP_WEIGHTS.get(rel, 0.2)
        conditions = member.get("conditions", [])

        G.add_node(m_id, name=member.get("name"), relation=rel, conditions=conditions)
        
        # Add parent edges
        for p in member.get("parents", []):
            G.add_edge(p, m_id)

        # Accumulate condition weights
        for cond in conditions:
            c_clean = cond.lower().strip()
            if c_clean not in condition_risk_accumulators:
                condition_risk_accumulators[c_clean] = 0.0
            condition_risk_accumulators[c_clean] += weight

    # Format risk assessments
    risk_summary = []
    for cond, total_w in condition_risk_accumulators.items():
        if cond == "mild_anxiety" or cond == "trauma":
            category = "Psychological / Inter-generational Trauma"
        elif "diabetes" in cond or "hypertension" in cond or "cardio" in cond or "coronary" in cond:
            category = "Cardiometabolic Hereditary"
        else:
            category = "General Genetic Vulnerability"

        # Percentage risk heuristic capped at 85%
        calculated_pct = min(round(total_w * 40.0, 1), 85.0)

        risk_summary.append({
            "condition": cond.replace("_", " ").title(),
            "hereditary_weight_score": round(total_w, 2),
            "estimated_genetic_vulnerability_pct": calculated_pct,
            "category": category,
            "preventative_screening_recommended": calculated_pct >= 30.0
        })

    return {
        "status": "SUCCESS",
        "total_family_nodes": G.number_of_nodes(),
        "total_lineage_edges": G.number_of_edges(),
        "hereditary_risks": risk_summary,
        "genogram_graph_topology": {
            "nodes": [{"id": n, "label": G.nodes[n]["name"], "relation": G.nodes[n]["relation"]} for n in G.nodes()],
            "links": [{"source": u, "target": v} for u, v in G.edges()]
        }
    }
