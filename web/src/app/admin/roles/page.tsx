'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import { useAuth } from '@/lib/auth/AuthContext';
import { authApi, UserProfile, RoleEnum } from '@/lib/auth/authApi';

const AVAILABLE_ROLES: RoleEnum[] = [
  'PATIENT',
  'SOLDIER',
  'VICTIM',
  'CITIZEN',
  'PHYSICIAN',
  'WELFARE_OFFICER',
  'COUNSELOR',
  'COMMANDER',
  'DISTRICT_OFFICER',
  'STATE_ADMIN',
  'SYSTEM_ADMIN',
];

export default function AdminRolesPage() {
  const { user, loading: authLoading } = useAuth();
  const [users, setUsers] = useState<UserProfile[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string>('');
  const [selectedUser, setSelectedUser] = useState<UserProfile | null>(null);
  const [selectedRoles, setSelectedRoles] = useState<RoleEnum[]>([]);
  const [saving, setSaving] = useState<boolean>(false);
  const [successMsg, setSuccessMsg] = useState<string>('');

  const fetchUsers = async () => {
    setLoading(true);
    setError('');
    try {
      const data = await authApi.listAllUsers();
      setUsers(data);
    } catch (err: unknown) {
      if (err instanceof Error) {
        setError(err.message);
      } else {
        setError('Failed to fetch user directory');
      }
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (user?.is_admin) {
      fetchUsers();
    }
  }, [user]);

  const handleOpenModal = (targetUser: UserProfile) => {
    setSelectedUser(targetUser);
    setSelectedRoles(targetUser.mapped_roles || [targetUser.primary_role]);
    setSuccessMsg('');
  };

  const toggleRole = (role: RoleEnum) => {
    if (selectedRoles.includes(role)) {
      setSelectedRoles(selectedRoles.filter((r) => r !== role));
    } else {
      setSelectedRoles([...selectedRoles, role]);
    }
  };

  const handleSaveRoles = async () => {
    if (!selectedUser) return;
    setSaving(true);
    setSuccessMsg('');
    setError('');
    try {
      await authApi.mapUserRoles(selectedUser.id, selectedRoles);
      setSuccessMsg(`Successfully updated mapped roles for ${selectedUser.full_name}!`);
      setSelectedUser(null);
      await fetchUsers();
    } catch (err: unknown) {
      if (err instanceof Error) {
        setError(err.message);
      } else {
        setError('Failed to save roles');
      }
    } finally {
      setSaving(false);
    }
  };

  if (authLoading || loading) {
    return (
      <div className="min-h-[calc(100vh-4rem)] flex items-center justify-center bg-slate-50 text-slate-600 font-sans">
        <div className="flex items-center gap-3">
          <svg className="animate-spin h-5 w-5 text-indigo-600" fill="none" viewBox="0 0 24 24">
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          <span className="text-sm font-bold">Loading User Directory...</span>
        </div>
      </div>
    );
  }

  if (!user?.is_admin) {
    return (
      <div className="min-h-[calc(100vh-4rem)] flex flex-col items-center justify-center p-6 bg-slate-50 text-slate-900 text-center space-y-4 font-sans">
        <h2 className="text-2xl font-black text-rose-700">Access Restricted</h2>
        <p className="text-xs text-slate-500 max-w-sm">
          Admin Role Management is reserved strictly for System Administrators.
        </p>
        <Link href="/dashboard" className="px-5 py-2.5 rounded-xl bg-slate-900 text-white text-xs font-bold shadow-sm">
          Return to Dashboard
        </Link>
      </div>
    );
  }

  return (
    <div className="min-h-[calc(100vh-4rem)] bg-slate-50 text-slate-900 font-sans p-6 sm:p-8 space-y-8">
      <div className="max-w-6xl mx-auto space-y-8">
        
        {/* Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white border border-slate-200 rounded-2xl p-6 shadow-sm">
          <div>
            <div className="inline-block px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider bg-amber-50 text-amber-800 border border-amber-200 mb-2">
              System Admin Portal
            </div>
            <h1 className="text-2xl font-black text-slate-900 tracking-tight">RBAC Role Assignment &amp; Mapping</h1>
            <p className="text-xs text-slate-500 mt-1">
              Assign multi-tier operational security roles to users across all 4 applications.
            </p>
          </div>
          <Link
            href="/dashboard"
            className="px-4 py-2.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-bold border border-slate-200 transition"
          >
            &larr; Back to Dashboard
          </Link>
        </div>

        {successMsg && (
          <div className="p-4 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-800 text-xs font-bold">
            {successMsg}
          </div>
        )}

        {error && (
          <div className="p-4 rounded-xl bg-rose-50 border border-rose-200 text-rose-800 text-xs font-bold">
            {error}
          </div>
        )}

        {/* Users Table */}
        <div className="bg-white border border-slate-200 rounded-2xl shadow-sm overflow-hidden">
          <div className="p-4 border-b border-slate-200 flex justify-between items-center bg-slate-50">
            <h2 className="text-xs font-bold text-slate-700 uppercase tracking-wider">Registered Platform Users ({users.length})</h2>
            <button onClick={fetchUsers} className="text-xs font-bold text-indigo-600 hover:underline">
              Refresh Directory
            </button>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-slate-100 border-b border-slate-200 text-slate-600 font-bold uppercase tracking-wider">
                <tr>
                  <th className="p-4">User Name</th>
                  <th className="p-4">Identifier</th>
                  <th className="p-4">Primary Role</th>
                  <th className="p-4">Mapped RBAC Roles</th>
                  <th className="p-4 text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-200">
                {users.map((u) => (
                  <tr key={u.id} className="hover:bg-slate-50 transition">
                    <td className="p-4 font-bold text-slate-900">
                      {u.full_name}
                      {u.is_admin && (
                        <span className="ml-2 px-2 py-0.5 rounded text-[9px] font-bold bg-amber-100 text-amber-800 border border-amber-300">
                          ADMIN
                        </span>
                      )}
                    </td>
                    <td className="p-4 font-mono text-slate-600">{u.email_or_phone}</td>
                    <td className="p-4 font-bold text-indigo-600">{u.primary_role}</td>
                    <td className="p-4">
                      <div className="flex flex-wrap gap-1">
                        {u.mapped_roles.map((r: string) => (
                          <span
                            key={r}
                            className="px-2 py-0.5 rounded bg-slate-100 text-slate-700 font-mono text-[10px] border border-slate-200 font-semibold"
                          >
                            {r}
                          </span>
                        ))}
                      </div>
                    </td>
                    <td className="p-4 text-right">
                      <button
                        onClick={() => handleOpenModal(u)}
                        className="px-3 py-1.5 rounded-lg bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs shadow-sm transition"
                      >
                        Edit Roles
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Modal for Role Mapping */}
        {selectedUser && (
          <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-sm flex items-center justify-center p-6 z-50">
            <div className="max-w-md w-full bg-white border border-slate-200 rounded-2xl p-6 space-y-6 shadow-2xl">
              <div>
                <h3 className="text-lg font-bold text-slate-900">Assign Roles: {selectedUser.full_name}</h3>
                <p className="text-xs text-slate-500 font-mono mt-0.5">{selectedUser.email_or_phone}</p>
              </div>

              <div className="space-y-2">
                <label className="block text-xs font-bold uppercase text-slate-600 tracking-wider">
                  Select Applicable RBAC Roles:
                </label>
                <div className="grid grid-cols-2 gap-2 max-h-60 overflow-y-auto pr-1">
                  {AVAILABLE_ROLES.map((role) => {
                    const isChecked = selectedRoles.includes(role);
                    return (
                      <button
                        key={role}
                        type="button"
                        onClick={() => toggleRole(role)}
                        className={`p-2.5 rounded-xl text-xs font-bold border transition text-left flex items-center justify-between ${
                          isChecked
                            ? 'bg-indigo-50 border-indigo-500 text-indigo-700'
                            : 'bg-slate-50 border-slate-200 text-slate-600 hover:border-slate-300'
                        }`}
                      >
                        <span>{role}</span>
                        {isChecked && <span className="font-bold text-indigo-600">&check;</span>}
                      </button>
                    );
                  })}
                </div>
              </div>

              <div className="flex justify-end gap-3 pt-4 border-t border-slate-100">
                <button
                  onClick={() => setSelectedUser(null)}
                  className="px-4 py-2 rounded-xl bg-slate-100 text-slate-700 text-xs font-bold hover:bg-slate-200"
                >
                  Cancel
                </button>
                <button
                  onClick={handleSaveRoles}
                  disabled={saving}
                  className="px-5 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-bold shadow-md shadow-indigo-600/20 disabled:opacity-50"
                >
                  {saving ? 'Saving...' : 'Save Role Mapping'}
                </button>
              </div>
            </div>
          </div>
        )}

      </div>
    </div>
  );
}
