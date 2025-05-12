import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()
    
    // Replace with your actual Supabase URL and anon key
    let client = SupabaseClient(
        supabaseURL: URL(string: "https://eklzpqrwqfohuwlomidi.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVrbHpwcXJ3cWZvaHV3bG9taWRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDcwNzQ5MDMsImV4cCI6MjA2MjY1MDkwM30.p-UuibX9i-KIOtVneVDJ3HVWBp111LCj2Z5t_wUg-64"
    )
} 