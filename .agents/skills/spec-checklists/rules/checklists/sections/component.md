# Rules — Component Checklist

Create for new or modified UI only. Search app-memory and `sli_common`, select
cross-product/app/feature ownership, list typed constructor API and visual/
accessibility states, and require widget tests. Shared components do not depend
on a feature Cubit/BLoC; direct Shadcn imports stay inside `sli_common`.
