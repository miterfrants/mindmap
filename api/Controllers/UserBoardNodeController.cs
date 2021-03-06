using System;
using System.Net;
using System.Linq;
using System.Collections.Generic;

using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;

using Mindnote.Models;
using Mindnote.Services;
using Mindnote.Util;

namespace Mindnote.Controllers
{
    [Authorize]
    [Route("mindnote/api/v1/users/me/boards/{boardId}/nodes/{nodeId}/")]
    [ApiController]
    public class UserBoardNodeController : ControllerBase
    {
        private readonly MindnoteContext _context;
        private readonly MindnoteContextForView _contextForView;
        private readonly UserService _userService;
        public UserBoardNodeController(MindnoteContext context, MindnoteContextForView contextForView, UserService userService)
        {
            _context = context;
            _contextForView = contextForView;
            _userService = userService;
        }

        [HttpGet]
        public ActionResult<view_node> GetNodeInBoard([FromRoute] Int32 boardId, [FromRoute] Int32 nodeId)
        {
            string authorization = Request.Headers["Authorization"];
            string token = authorization.Substring("Bearer ".Length).Trim();
            Int16 userId = _userService.GetUserId(token);
            board board = _context.board.FirstOrDefault(x => x.id == boardId && x.owner_id == userId && x.deleted_at == null);

            if (board == null)
            {
                throw new MindnoteException("嗚喔！ 分類已經被刪除，無法瀏覽", HttpStatusCode.NotFound);
            }

            view_node node = _contextForView.view_node.FirstOrDefault(x => x.board_id == board.id && x.deleted_at == null && x.id == nodeId);
            return node;
        }

        [HttpPatch]
        public ActionResult<node> PatchNode([FromRoute] Int32 boardId, [FromRoute] Int16 nodeId, [FromBody] dynamic requestBody)
        {
            string authorization = Request.Headers["Authorization"];
            string token = authorization.Substring("Bearer ".Length).Trim();
            Int16 userId = _userService.GetUserId(token);

            node node = _context.node.FirstOrDefault(x => x.id == nodeId && x.owner_id == userId && x.board_id == boardId && x.deleted_at == null);

            if (node == null)
            {
                throw new MindnoteException("嗚喔！ 分類已經被刪除，無法瀏覽", HttpStatusCode.NotFound);
            }
            if (requestBody.title != null)
            {
                node.title = requestBody.title;
            }
            if (requestBody.description != null)
            {
                node.description = requestBody.description;
            }
            if (requestBody.x != null)
            {
                node.x = requestBody.x;
            }
            if (requestBody.y != null)
            {
                node.y = requestBody.y;
            }

            if (requestBody.cover != null)
            {
                node.cover = requestBody.cover;
            }

            node.updated_at = DateTime.Now;

            _context.SaveChanges();
            return node;
        }

        [HttpDelete]
        public ActionResult<dynamic> DeleteNode([FromRoute] Int32 boardId, [FromRoute] Int16 nodeId)
        {
            string authorization = Request.Headers["Authorization"];
            string token = authorization.Substring("Bearer ".Length).Trim();

            Int16 userId = _userService.GetUserId(token);
            node node = _context.node.FirstOrDefault(x => x.id == nodeId && x.owner_id == userId && x.board_id == boardId && x.deleted_at == null);

            if (node is null)
            {
                throw new MindnoteException("筆記已經找不到了 Q_Q", HttpStatusCode.NotFound);
            }
            else
            {
                node.deleted_at = DateTime.Now;
            }

            List<node_relationship> relationships = _context.node_relationship.Where(x => (x.child_node_id == node.id || x.parent_node_id == node.id) && x.deleted_at == null).ToList();
            foreach (node_relationship relationship in relationships)
            {
                relationship.deleted_at = DateTime.Now;
            }

            node.updated_at = DateTime.Now;

            Int32 deleteResult = _context.SaveChanges();
            JSONResponse result = new JSONResponse(JSONResponseStatus.OK, new { });
            return result.toResponseObj();
        }
    }
}