import os
import sys

# Ensure backend directory is in sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "backend")))

from app.services.ai.registry import agent_registry
import app.services.ai.agents  # Trigger registration
from app.services.ai.tools import execute_tool_by_name

def test_nyaya_manas_ai():
    print("=== TESTING NYAYA-MANAS AI ENGINE & TOOLS ===")
    
    # 1. Test Tools directly
    print("\n1. Testing calculate_sc_st_compensation_tool:")
    res1 = execute_tool_by_name("calculate_sc_st_compensation_tool", {"offense_category": "rape", "case_stage": "fir"})
    print("Result:", res1)
    assert res1["current_tranche_disbursement_inr"] == 412500, "Compensation calculation failed"

    print("\n2. Testing generate_xai_explainability_tool:")
    res2 = execute_tool_by_name("generate_xai_explainability_tool", {"victim_id": "V-102", "distress_score": 78})
    print("Result:", res2)
    assert "feature_contributions" in res2, "XAI tool failed"

    print("\n3. Testing ivrs_helpline_triage_tool:")
    res3 = execute_tool_by_name("ivrs_helpline_triage_tool", {"caller_phone_hash": "HASH998", "speech_language": "hi", "dtmf_choice": 1})
    print("Result:", res3)
    assert res3["helpline_number"] == "14566 (NHAA)", "IVRS tool failed"

    # 2. Test Agent Registry
    print("\n4. Testing Registered Agents:")
    agents = agent_registry.list_agents()
    print("Registered Agents Count:", len(agents))
    for a in agents:
        print(f" - [{a['agent_id']}] {a['name']}: {a['description']}")


    print("\n✅ ALL NYAYA-MANAS BACKEND AI TESTS PASSED PERFECTLY!")

if __name__ == "__main__":
    test_nyaya_manas_ai()
